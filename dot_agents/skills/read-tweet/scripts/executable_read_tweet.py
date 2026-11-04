#!/usr/bin/env python3
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""Read X/Twitter posts, with their thread, from URLs. No login or API key.

Every post is read in thread context automatically. You get the parent chain
up to the conversation root, plus the focal author's self-thread both up and
down, in order. The default output is compact. Flags raise the limits, and the
output's "more:" lines say which flag to use when something was left out.

Sources, tried in order (all public, no auth):
  1. api.fxtwitter.com/2/thread/<id>   full thread, media, quotes, stats (unofficial)
  2. api.fxtwitter.com/status/<id>     single post; parents walked one by one (no posts below)
  3. publish.x.com/oembed              X's official embed: text only, no thread context
Replies from other people come from api.fxtwitter.com/2/conversation/<id> (--replies).
"""

from __future__ import annotations

import argparse
import html
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from collections.abc import Iterator, Mapping, Sequence
from dataclasses import asdict, dataclass, field, replace
from datetime import datetime, timezone
from enum import Enum
from typing import Any, Callable, Optional, Union

Json = Mapping[str, Any]
GetJson = Callable[[str], Json]

USER_AGENT = "read-tweet/2.0"
HTTP_OK = 200
HTTP_TIMEOUT_S = 30
ALT_TEXT_MAX = 300  # alt text can run to paragraphs
REPLY_PAGES_MAX = 5
STATUS_ID = re.compile(r"/status(?:es)?/(\d{1,25})")
STAT_KEYS = ("replies", "reposts", "likes", "quotes", "views")


class SourceError(Exception):
    """A source could not provide a post: network, HTTP or payload error."""


class Source(Enum):
    """Where a thread came from, best first."""

    THREAD = "fxtwitter /2/thread"
    PARENTS = "fxtwitter /status (parents only)"
    OEMBED = "oembed (text only)"


class Role(Enum):
    """A post's relation to the one the user linked."""

    FOCAL = "focal"
    AUTHOR = "author"  # same author as the focal post
    CONTEXT = "context"  # someone else, above the focal post


@dataclass(frozen=True)
class Limits:
    """Output budget. 0 disables a cap."""

    max_posts: int = 30
    max_chars: int = 2000
    quote_depth: int = 1
    replies: int = 0


# Model


@dataclass(frozen=True)
class Ref:
    """A pointer to a post that wasn't expanded."""

    id: str
    handle: Optional[str] = None
    url: Optional[str] = None


@dataclass(frozen=True)
class Media:
    """One photo, video or gif."""

    type: str
    url: str
    alt: str = ""
    thumbnail: str = ""
    duration_s: Optional[float] = None


@dataclass(frozen=True)
class Tombstone:
    """A deleted, protected or otherwise unreachable post."""

    id: str
    reason: str
    url: Optional[str] = None
    handle: Optional[str] = None


@dataclass(frozen=True)
class Post:
    """One readable post."""

    id: str
    url: Optional[str]
    author: Optional[str]
    handle: Optional[str]
    date: Optional[str]
    text: str
    reply_to: Optional[Ref] = None
    stats: Mapping[str, int] = field(default_factory=dict)
    media: tuple[Media, ...] = ()
    community_note: Optional[str] = None
    article: Optional[str] = None
    card: Optional[str] = None
    quote: Optional[Entry] = None
    quote_ref: Optional[Ref] = None  # a quote beyond --quote-depth
    quote_known: bool = True  # False: the payload didn't say whether this post quotes another
    truncated_chars: int = 0

    @property
    def replies(self) -> int:
        """Reply count, 0 when unknown."""
        return self.stats.get("replies", 0)


Entry = Union[Post, Tombstone]


def ref_to(entry: Entry) -> Ref:
    """A Ref pointing at entry."""
    return Ref(entry.id, entry.handle, entry.url)


def same_handle(a: Optional[str], b: Optional[str]) -> bool:
    """Compare X handles, which are case-insensitive."""
    return (a or "").lower() == (b or "").lower()


# Parsing: pure functions, no I/O


def tweet_id(arg: str) -> Optional[str]:
    """The status ID in a URL, or arg itself if it's a bare ID."""
    arg = arg.strip()
    if arg.isdigit():
        return arg
    match = STATUS_ID.search(arg)
    return match.group(1) if match else None


def parse_post(raw: Json, *, top_level: bool = True) -> Entry:
    """Normalise one fxtwitter post (v1 /status or v2 /2/...)."""
    author = raw.get("author")
    if not author or raw.get("type") == "tombstone":
        reason = raw.get("reason") or raw.get("message") or "unavailable"
        return Tombstone(str(raw.get("id")), reason, raw.get("url"))
    quote = raw.get("quote")
    return Post(
        id=str(raw["id"]),
        url=raw.get("url"),
        author=author.get("name"),
        handle=author.get("screen_name"),
        date=_date(raw),
        text=raw.get("text") or "",
        reply_to=_reply_ref(raw),
        stats=_stats(raw),
        media=tuple(_media(m) for m in (raw.get("media") or {}).get("all") or ()),
        community_note=_community_note(raw.get("community_note")),
        article=_article(raw.get("article")),
        card=_card(raw.get("card") or raw.get("twitter_card")),
        quote=parse_post(quote, top_level=False) if quote else None,
        quote_known=top_level or "quote" in raw,
    )


def _date(raw: Json) -> Optional[str]:
    ts = raw.get("created_timestamp")
    if not ts:
        return raw.get("created_at")
    return datetime.fromtimestamp(ts, timezone.utc).strftime("%Y-%m-%d %H:%MZ")


def _reply_ref(raw: Json) -> Optional[Ref]:
    target = raw.get("replying_to")
    if isinstance(target, Mapping):  # v2: {"screen_name", "status", "url"}
        status = target.get("status")
        return Ref(str(status), target.get("screen_name"), target.get("url")) if status else None
    status = raw.get("replying_to_status")  # v1: handle and ID in separate fields
    return Ref(str(status), target) if status else None


def _stats(raw: Json) -> dict[str, int]:
    values = {key: raw.get(key) for key in STAT_KEYS}
    if values["reposts"] is None:
        values["reposts"] = raw.get("retweets")  # v1 name
    return {key: value for key, value in values.items() if isinstance(value, int)}


def _media(raw: Json) -> Media:
    duration = raw.get("duration")
    return Media(
        type=raw.get("type") or "media",
        url=raw.get("url") or "",
        alt=clip(raw.get("altText") or "", ALT_TEXT_MAX)[0],
        thumbnail=raw.get("thumbnail_url") or "",
        duration_s=round(duration, 1) if duration else None,
    )


def _community_note(note: object) -> Optional[str]:
    if isinstance(note, Mapping):
        return note.get("text")
    return note if isinstance(note, str) and note else None


def _article(article: object) -> Optional[str]:
    if not isinstance(article, Mapping):
        return None
    return f"{article.get('title')}: {article.get('preview_text')}"


def _card(card: object) -> Optional[str]:
    return card.get("title") if isinstance(card, Mapping) else None


def parse_oembed(tid: str, payload: Json) -> Post:
    """Plain-text post from X's oEmbed HTML."""
    markup = payload.get("html") or ""
    match = re.search(r"<p[^>]*>(.*?)</p>", markup, re.DOTALL)
    body = re.sub(r"<br\s*/?>", "\n", match.group(1) if match else "")
    body = re.sub(r'<a href="([^"]+)"[^>]*>[^<]*</a>', r"\1", body)
    body = html.unescape(re.sub(r"<[^>]+>", "", body)).strip()
    dates = re.findall(r">([A-Z][a-z]+ \d{1,2}, \d{4})</a>", markup)
    return Post(
        id=tid,
        url=payload.get("url"),
        author=payload.get("author_name"),
        handle=(payload.get("author_url") or "").rsplit("/", 1)[-1] or None,
        date=dates[-1] if dates else None,
        text=body,
    )


# Budgeting: pure functions, no I/O


def clip(text: str, limit: int) -> tuple[str, int]:
    """Truncate text to limit chars (0 = no limit). Returns (text, chars dropped)."""
    if limit <= 0 or len(text) <= limit:
        return text, 0
    return text[:limit].rstrip() + "…", len(text) - limit


def clip_post(entry: Entry, limit: int) -> Entry:
    """Entry with its text truncated to limit chars."""
    if isinstance(entry, Tombstone):
        return entry
    text, dropped = clip(entry.text, limit)
    return replace(entry, text=text, truncated_chars=dropped) if dropped else entry


def shape_quotes(post: Post, levels: int, max_chars: int) -> Post:
    """Expand `levels` levels of quotes (clipped), turn the next level into a Ref, drop the rest."""
    quote = post.quote
    if quote is None:
        return post
    if levels <= 0:
        return replace(post, quote=None, quote_ref=ref_to(quote))
    if isinstance(quote, Post):
        quote = clip_post(shape_quotes(quote, levels - 1, max_chars), max_chars)
    return replace(post, quote=quote)


@dataclass(frozen=True)
class Gap:
    """Thread posts left out by --max-posts."""

    count: int
    before_position: int


def window(total: int, focal: int, max_posts: int) -> list[Union[int, Gap]]:
    """Indices to show: the root plus the max_posts-1 posts nearest focal, gaps marked."""
    if max_posts <= 0 or total <= max_posts:
        return list(range(total))
    span = max_posts - 1
    start = max(1, min(focal - span // 2, total - span))
    keep = [0, *range(start, start + span)]
    shown: list[Union[int, Gap]] = []
    for prev, index in zip([-1, *keep], [*keep, total]):
        if index - prev > 1:
            shown.append(Gap(index - prev - 1, index + 1))
        if index < total:
            shown.append(index)
    return shown


# Sources: all network access lives here


def http_get_json(url: str) -> Json:
    """GET url and decode a JSON object. fxtwitter's 4xx bodies are JSON too."""
    if not url.startswith(("https://", "http://")):
        msg = f"refusing non-HTTP URL {url!r}"
        raise SourceError(msg)
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})  # noqa: S310 (scheme checked)
    try:
        with urllib.request.urlopen(request, timeout=HTTP_TIMEOUT_S) as response:  # noqa: S310
            body = response.read()
    except urllib.error.HTTPError as err:
        body = err.read()
    except OSError as err:  # URLError, timeouts, connection errors
        raise SourceError(str(err)) from err
    try:
        data = json.loads(body)
    except ValueError as err:
        msg = f"non-JSON response from {url}"
        raise SourceError(msg) from err
    if not isinstance(data, dict):
        msg = f"unexpected payload from {url}"
        raise SourceError(msg)
    return data


@dataclass(frozen=True)
class Api:
    """The public endpoints, behind an injectable JSON getter."""

    get_json: GetJson = http_get_json
    fx_base: str = "https://api.fxtwitter.com"
    oembed_url: str = "https://publish.x.com/oembed"

    def _fx(self, path: str, payload_key: str) -> Json:
        data = self.get_json(f"{self.fx_base.rstrip('/')}/{path}")
        payload = data.get(payload_key)
        if (
            data.get("code") != HTTP_OK or not payload
        ):  # fxtwitter mirrors the HTTP status in the body
            msg = f"{path}: code {data.get('code')} {data.get('message') or ''}".rstrip()
            raise SourceError(msg)
        return data

    def thread(self, tid: str) -> list[Entry]:
        """The parent chain plus the focal author's self-thread, both directions."""
        data = self._fx(f"2/thread/{tid}", "status")
        raw = list(data.get("thread") or [])
        if not any(str(post.get("id")) == tid for post in raw):
            raw.append(data["status"])
        return [parse_post(post) for post in raw]

    def status(self, tid: str) -> Entry:
        """One post from the v1 endpoint, which survives some v2 outages."""
        return parse_post(self._fx(f"status/{tid}", "tweet")["tweet"])

    def status_v2(self, tid: str) -> Entry:
        """One post from the v2 endpoint, with its quote chain inlined."""
        return parse_post(self._fx(f"2/status/{tid}", "status")["status"])

    def replies_page(self, tid: str, cursor: Optional[str]) -> tuple[list[Entry], Optional[str]]:
        """One page of replies to tid, most-liked first, and the next cursor."""
        query = urllib.parse.urlencode(
            {"ranking_mode": "likes", **({"cursor": cursor} if cursor else {})}
        )
        data = self.get_json(f"{self.fx_base.rstrip('/')}/2/conversation/{tid}?{query}")
        replies = [parse_post(raw) for raw in data.get("replies") or ()]
        next_cursor = (data.get("cursor") or {}).get("bottom")
        return replies, next_cursor if replies else None

    def oembed(self, tid: str) -> Post:
        """Text-only post from X's official oEmbed endpoint."""
        query = urllib.parse.urlencode(
            {"url": f"https://x.com/i/status/{tid}", "omit_script": "1", "dnt": "1"}
        )
        payload = self.get_json(f"{self.oembed_url}?{query}")
        if not payload.get("html"):
            msg = "oEmbed returned no post"
            raise SourceError(msg)
        return parse_oembed(tid, payload)


def walk_parents(api: Api, tid: str, max_posts: int) -> list[Entry]:
    """Fallback thread: the post and its parents, oldest first. Nothing below the post."""
    chain = [api.status(tid)]
    while len(chain) < max(max_posts, 1):
        last = chain[-1]
        if not isinstance(last, Post) or last.reply_to is None:
            break
        try:
            chain.append(api.status(last.reply_to.id))
        except SourceError as err:
            chain.append(Tombstone(last.reply_to.id, str(err)))
            break
    return chain[::-1]


def fill_quotes(post: Post, api: Api, levels: int) -> Post:
    """Refetch quoted posts so the quote chain is known `levels` deep.

    /2/thread inlines a post's quote but not that quote's own quote.
    """
    quote = post.quote
    if levels <= 0 or not isinstance(quote, Post):
        return post
    if not quote.quote_known:
        try:
            quote = api.status_v2(quote.id)
        except SourceError:
            return post
        if not isinstance(quote, Post):
            return post
    return replace(post, quote=fill_quotes(quote, api, levels - 1))


# Thread


@dataclass(frozen=True)
class Thread:
    """The posts around one focal post, oldest first."""

    focal_id: str
    source: Source
    entries: tuple[Entry, ...]

    @property
    def focal_index(self) -> int:
        """Position of the focal post in entries."""
        ids = [entry.id for entry in self.entries]
        return ids.index(self.focal_id) if self.focal_id in ids else len(ids) - 1

    @property
    def focal(self) -> Entry:
        """The post the user linked."""
        return self.entries[self.focal_index]

    @property
    def root(self) -> Optional[Post]:
        """The conversation root, or None when the top of the chain wasn't reached."""
        first = self.entries[0]
        if self.source is Source.OEMBED or not isinstance(first, Post) or first.reply_to:
            return None
        return first

    def role(self, index: int) -> Role:
        """How entries[index] relates to the focal post."""
        if index == self.focal_index:
            return Role.FOCAL
        if same_handle(self.entries[index].handle, self.focal.handle):
            return Role.AUTHOR
        return Role.CONTEXT

    def author_chain(self) -> list[Post]:
        """The focal author's posts."""
        return [
            e
            for i, e in enumerate(self.entries)
            if isinstance(e, Post) and self.role(i) is not Role.CONTEXT
        ]

    def author_continues(self) -> bool:
        """Whether the focal author posted again below the focal post."""
        below = self.entries[self.focal_index + 1 :]
        return any(same_handle(e.handle, self.focal.handle) for e in below)


def load_thread(api: Api, tid: str, max_posts: int) -> Thread:
    """The thread around tid from the best source that answers."""
    loaders: list[tuple[Source, Callable[[], Sequence[Entry]]]] = [
        (Source.THREAD, lambda: api.thread(tid)),
        (Source.PARENTS, lambda: walk_parents(api, tid, max_posts)),
        (Source.OEMBED, lambda: [api.oembed(tid)]),
    ]
    errors = []
    for source, load in loaders:
        try:
            return Thread(tid, source, tuple(load()))
        except SourceError as err:  # noqa: PERF203 (three tries at most)
            errors.append(f"{source.value}: {err}")
    errors.append("deleted, protected, age-restricted, or all sources down")
    raise SourceError("; ".join(errors))


def budget(thread: Thread, api: Api, limits: Limits) -> Thread:
    """Apply the quote and text limits. The focal post's text is never clipped."""

    def shape(index: int, entry: Entry) -> Entry:
        if isinstance(entry, Tombstone):
            return entry
        is_focal = index == thread.focal_index
        # Expanding N levels needs N-1 known; the focal post also learns whether level N quotes on.
        levels = limits.quote_depth if is_focal else limits.quote_depth - 1
        if thread.source is not Source.OEMBED:
            entry = fill_quotes(entry, api, levels)
        entry = shape_quotes(entry, limits.quote_depth, limits.max_chars)
        return entry if is_focal else clip_post(entry, limits.max_chars)

    return replace(thread, entries=tuple(shape(i, e) for i, e in enumerate(thread.entries)))


# Report


@dataclass(frozen=True)
class Report:
    """Everything printed for one input."""

    input: str
    thread: Thread
    shown: list[Union[int, Gap]]
    replies: Optional[list[Entry]] = None
    replies_from_others: Optional[int] = None
    notes: list[str] = field(default_factory=list)
    more: list[str] = field(default_factory=list)


@dataclass(frozen=True)
class Failure:
    """An input that produced no post."""

    input: str
    error: str


def fetch_replies(api: Api, thread: Thread, limit: int, max_chars: int) -> list[Entry]:
    """The top `limit` replies to the focal post from people outside the thread."""
    in_thread = {entry.id for entry in thread.entries}
    found: list[Entry] = []
    cursor: Optional[str] = None
    for _ in range(REPLY_PAGES_MAX):
        page, cursor = api.replies_page(thread.focal_id, cursor)
        found += [
            clip_post(shape_quotes(r, 0, 0), max_chars) if isinstance(r, Post) else r
            for r in page
            if r.id not in in_thread
        ]
        if len(found) >= limit or not cursor:
            break
    return found[:limit]


def thread_notes(thread: Thread) -> Iterator[str]:
    """Gaps in what the sources returned."""
    if thread.source is Source.THREAD and thread.root is None:
        yield "thread root is missing (deleted, protected or unreachable); context above it is lost"
    if any(isinstance(entry, Tombstone) for entry in thread.entries):
        yield "some posts in the chain are unavailable (shown as UNAVAILABLE)"
    if thread.source is Source.PARENTS:
        yield (
            "thread endpoint failed: posts after this one were NOT fetched; "
            "ask the user for the last post's link"
        )
    if thread.source is Source.OEMBED:
        yield (
            "oEmbed fallback: no media, quotes, stats or thread context; "
            "a quoted post appears only as a t.co link"
        )


def budget_hints(thread: Thread, shown: Sequence[Union[int, Gap]], limits: Limits) -> Iterator[str]:
    """What the limits left out, and the flag that brings it back."""
    hidden = sum(item.count for item in shown if isinstance(item, Gap))
    if hidden:
        yield f"{hidden} thread posts not shown: --max-posts {len(thread.entries)}"
    if (
        thread.source is Source.PARENTS
        and thread.root is None
        and isinstance(thread.entries[0], Post)
    ):
        yield f"parent walk stopped at {limits.max_posts}: --max-posts {limits.max_posts * 2}"
    posts = [entry for entry in thread.entries if isinstance(entry, Post)]
    if any(post.truncated_chars for post in posts):
        yield "some post text truncated: --max-chars 0"
    if any(_has_quote_ref(post) for post in posts):
        yield f"deeper quoted posts shown as links only: --quote-depth {limits.quote_depth + 1}"
    root = thread.root
    if root and not same_handle(root.handle, thread.focal.handle):
        yield (
            f"focal post replies into @{root.handle}'s conversation; "
            "this shows only the chain above it. "
            f"For @{root.handle}'s own full thread run on the root: {root.url}"
        )


def _has_quote_ref(post: Post) -> bool:
    return post.quote_ref is not None or (
        isinstance(post.quote, Post) and _has_quote_ref(post.quote)
    )


def build_report(arg: str, api: Api, limits: Limits) -> Union[Report, Failure]:
    """Fetch, budget and annotate the thread for one input."""
    tid = tweet_id(arg)
    if tid is None:
        return Failure(arg, "no tweet ID in input; need a .../status/<id> URL or a numeric ID")
    try:
        thread = budget(load_thread(api, tid, limits.max_posts), api, limits)
    except SourceError as err:
        return Failure(arg, str(err))

    shown = window(len(thread.entries), thread.focal_index, limits.max_posts)
    more = list(budget_hints(thread, shown, limits))
    if thread.source is not Source.THREAD:  # reply counts need the whole author chain
        return Report(arg, thread, shown, notes=list(thread_notes(thread)), more=more)
    others = replies_from_others(thread)
    replies = (
        fetch_replies(api, thread, limits.replies, limits.max_chars) if limits.replies else None
    )
    more += reply_hints(thread, replies, others, limits.replies)
    return Report(arg, thread, shown, replies, others, list(thread_notes(thread)), more)


def replies_from_others(thread: Thread) -> int:
    """Approximate replies to the author's chain, minus the author's own continuations."""
    chain = thread.author_chain()
    return max(0, sum(post.replies for post in chain) - (len(chain) - 1))


def reply_hints(
    thread: Thread, replies: Optional[list[Entry]], others: int, asked: int
) -> Iterator[str]:
    """Hint at replies that weren't fetched."""
    if replies is None:
        if others:
            yield f"~{others} replies from other people not fetched: --replies 10 (top, by likes)"
        return
    focal = thread.focal
    expected = (focal.replies if isinstance(focal, Post) else 0) - int(thread.author_continues())
    # fxtwitter returns a bottom cursor even when nothing is left, so compare counts instead.
    if len(replies) < expected:
        yield f"more replies to the focal post exist: --replies {asked * 3}"


# Text output


def render_entry(entry: Entry, indent: str = "") -> list[str]:
    """One post as indented lines."""
    if isinstance(entry, Tombstone):
        return [f"{indent}UNAVAILABLE {entry.url or entry.id} ({entry.reason})"]
    return [indent + line for line in _post_lines(entry)] + _quote_lines(entry, indent)


def _post_lines(post: Post) -> Iterator[str]:
    yield f"{post.author} (@{post.handle}) · {post.date} · {post.url}"
    yield from post.text.splitlines()
    if post.truncated_chars:
        yield f"[… {post.truncated_chars} more chars]"
    if post.article:
        yield f"[X Article] {post.article}"
    if post.card:
        yield f"[link card] {post.card}"
    yield from map(_media_line, post.media)
    if post.community_note:
        yield from f"[Community note] {post.community_note}".splitlines()
    if post.stats:
        yield " · ".join(f"{key} {value}" for key, value in post.stats.items())


def _media_line(media: Media) -> str:
    line = f"[{media.type}] {media.url}"
    if media.duration_s:
        line += f" ({media.duration_s}s, thumb {media.thumbnail})"
    return line + (f" alt: {media.alt}" if media.alt else "")


def _quote_lines(post: Post, indent: str) -> list[str]:
    if post.quote:
        return [f"{indent}> quoting:", *render_entry(post.quote, indent + "> ")]
    if post.quote_ref:
        ref = post.quote_ref
        return [f"{indent}> quoting @{ref.handle}: {ref.url} (not expanded)"]
    return []


def _headline(report: Report) -> str:
    thread = report.thread
    total = len(thread.entries)
    if total == 1:
        shape = (
            "single post (no parents, no self-replies)"
            if thread.source is Source.THREAD
            else "single post"
        )
    else:
        chain = len(thread.author_chain())
        parts = [
            f"{total} posts",
            f"focal is {thread.focal_index + 1}/{total}",
            f"{chain} by the focal author",
        ]
        if total > chain:
            parts.append(f"{total - chain} by others above it")
        shape = "thread: " + ", ".join(parts)
    root = thread.root
    if root:
        where = f"root @{root.handle} {root.url}"
    else:
        where = "thread context unknown" if thread.source is Source.OEMBED else "root not reached"
    return f"=== {shape} · {where} · source: {thread.source.value}"


def render(result: Union[Report, Failure]) -> str:
    """The full text block for one input."""
    if isinstance(result, Failure):
        return f"[{result.input}] ERROR: {result.error}"
    thread = result.thread
    total = len(thread.entries)
    tags = {Role.FOCAL: " ★ focal", Role.CONTEXT: " · other author", Role.AUTHOR: ""}
    out = [_headline(result), *(f"note: {note}" for note in result.notes)]
    for item in result.shown:
        if isinstance(item, Gap):
            out.append(f"\n[… {item.count} post{'s' * (item.count > 1)} omitted …]")
        else:
            out += [
                f"\n[{item + 1}/{total}{tags[thread.role(item)]}]",
                *render_entry(thread.entries[item]),
            ]
    if result.replies is not None:
        out.append(f"\n--- top {len(result.replies)} replies from others to the focal post ---")
        for reply in result.replies:
            out += ["", *render_entry(reply, "  ")]
    if result.more:
        out += ["\nmore:", *(f"  - {hint}" for hint in result.more)]
    return "\n".join(out)


# JSON output


def _prune(data: Mapping[str, Any]) -> dict[str, Any]:
    """Drop None, empty and zero fields (stats excepted) so the JSON stays small."""
    pruned: dict[str, Any] = {}
    for key, value in data.items():
        if isinstance(value, Mapping):
            value = _prune(value)  # noqa: PLW2901
        elif isinstance(value, (list, tuple)):
            value = [_prune(v) if isinstance(v, Mapping) else v for v in value]  # noqa: PLW2901
        if key in STAT_KEYS or (value not in (None, "", [], {}, 0) and key != "quote_known"):
            pruned[key] = value
    return pruned


def entry_json(entry: Union[Entry, Ref]) -> dict[str, Any]:
    """An entry as a JSON-ready dict."""
    data = asdict(entry)
    if isinstance(entry, Tombstone):
        data["unavailable"] = data.pop("reason")
    return _prune(data)


def to_json(result: Union[Report, Failure]) -> dict[str, Any]:
    """One result as a JSON-ready dict, mirroring the text output."""
    if isinstance(result, Failure):
        return asdict(result)
    thread = result.thread
    root = thread.root
    posts: list[dict[str, Any]] = []
    for item in result.shown:
        if isinstance(item, Gap):
            posts.append({"omitted": item.count, "before_position": item.before_position})
        else:
            role = thread.role(item).value
            posts.append({"position": item + 1, "role": role, **entry_json(thread.entries[item])})
    return {
        "input": result.input,
        "id": thread.focal_id,
        "source": thread.source.value,
        "url": thread.focal.url,
        "total_posts": len(thread.entries),
        "focal_position": thread.focal_index + 1,
        "author_posts": len(thread.author_chain()),
        "root": entry_json(ref_to(root)) if root else None,
        "posts": posts,
        "replies_from_others_approx": result.replies_from_others,
        "replies": [entry_json(r) for r in result.replies] if result.replies is not None else None,
        "notes": result.notes,
        "more": result.more,
    }


# CLI


def parse_args(argv: Optional[Sequence[str]]) -> argparse.Namespace:
    """The command line."""
    limits = Limits()
    parser = argparse.ArgumentParser(
        prog="read-tweet", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("tweets", nargs="+", help="status URLs (x.com, twitter.com, ...) or IDs")
    parser.add_argument("--json", action="store_true", help="emit JSON instead of text")
    options = {
        "--max-posts": (
            limits.max_posts,
            "thread posts to show: root + nearest the focal; 0 = all",
        ),
        "--max-chars": (limits.max_chars, "per-post text cap, focal post exempt; 0 = no cap"),
        "--quote-depth": (limits.quote_depth, "levels of quoted posts to expand"),
        "--replies": (limits.replies, "also fetch the top N replies from others to the focal"),
    }
    for flag, (default, help_text) in options.items():
        parser.add_argument(
            flag, type=int, default=default, metavar="N", help=f"{help_text} (default %(default)s)"
        )
    return parser.parse_args(argv)


def api_from_env(environ: Mapping[str, str]) -> Api:
    """Endpoints, overridable for testing the fallbacks."""
    defaults = Api()
    return Api(
        fx_base=environ.get("READ_TWEET_FXTWITTER", defaults.fx_base),
        oembed_url=environ.get("READ_TWEET_OEMBED", defaults.oembed_url),
    )


def run(args: argparse.Namespace, api: Api) -> tuple[str, int]:
    """Output text and exit status for parsed args."""
    limits = Limits(args.max_posts, args.max_chars, args.quote_depth, args.replies)
    results = [build_report(arg, api, limits) for arg in args.tweets]
    status = int(any(isinstance(result, Failure) for result in results))
    if args.json:
        payload = [to_json(result) for result in results]
        return json.dumps(
            payload if len(payload) > 1 else payload[0], indent=2, ensure_ascii=False
        ), status
    return "\n\n".join(map(render, results)), status


def main(argv: Optional[Sequence[str]] = None) -> int:
    """CLI entry point."""
    output, status = run(parse_args(argv), api_from_env(os.environ))
    sys.stdout.write(output + "\n")
    return status


if __name__ == "__main__":
    raise SystemExit(main())
