"""Offline tests against API responses recorded 2026-11-04."""

from __future__ import annotations

import json
from typing import Any

import pytest
from conftest import Recorded, make_api, rt

PATIO11_THREAD = "2117385196471570809"  # 8-post self-thread; this is post 4
REPLY_INTO_THREAD = "2112663943491567663"  # @cipri_tom replying under @simonw's thread
QUOTE_CHAIN = "2112944161670488423"  # @simonw quoting a post that quotes him
FIRST_TWEET = "20"


def report(tid: str, get_json: Recorded | None = None, **limits: int) -> Any:
    return rt.build_report(tid, make_api(get_json or Recorded()), rt.Limits(**limits))


def text(tid: str, get_json: Recorded | None = None, **limits: int) -> str:
    return str(rt.render(report(tid, get_json, **limits)))


# ---------------------------------------------------------------- pure helpers


@pytest.mark.parametrize(
    ("arg", "expected"),
    [
        ("https://x.com/patio11/status/2117385196471570809?s=20", PATIO11_THREAD),
        ("https://twitter.com/jack/statuses/20", FIRST_TWEET),
        ("https://fxtwitter.com/a/status/123/photo/1", "123"),
        ("https://xcancel.com/a/status/456#m", "456"),
        (" 789 ", "789"),
        ("https://x.com/jack", None),
    ],
)
def test_tweet_id(arg: str, expected: str | None) -> None:
    assert rt.tweet_id(arg) == expected


@pytest.mark.parametrize(
    ("value", "limit", "expected"),
    [("abcdef", 0, ("abcdef", 0)), ("abcdef", 6, ("abcdef", 0)), ("abc def", 4, ("abc…", 3))],
)
def test_clip(value: str, limit: int, expected: tuple[str, int]) -> None:
    assert rt.clip(value, limit) == expected


def test_window_keeps_everything_under_the_cap() -> None:
    assert rt.window(5, 2, 30) == [0, 1, 2, 3, 4]
    assert rt.window(5, 2, 0) == [0, 1, 2, 3, 4]


def test_window_keeps_root_and_posts_around_focal() -> None:
    assert rt.window(10, 6, 4) == [0, rt.Gap(4, 6), 5, 6, 7, rt.Gap(2, 11)]


def test_window_from_first_and_last_post() -> None:
    assert rt.window(10, 0, 3) == [0, 1, 2, rt.Gap(7, 11)]
    assert rt.window(10, 9, 3) == [0, rt.Gap(7, 9), 8, 9]


def test_v1_and_v2_parse_to_the_same_core_fields(recorded: Recorded) -> None:
    api = make_api(recorded)
    v1 = api.status(REPLY_INTO_THREAD)
    v2 = next(e for e in api.thread(REPLY_INTO_THREAD) if e.id == REPLY_INTO_THREAD)
    for name in ("id", "handle", "date", "text", "reply_to"):
        if name == "reply_to":
            assert v1.reply_to.id == v2.reply_to.id
        else:
            assert getattr(v1, name) == getattr(v2, name)


# ---------------------------------------------------------------- threads


def test_self_thread_is_read_both_ways_from_the_middle() -> None:
    result = report(PATIO11_THREAD)
    thread = result.thread
    assert len(thread.entries) == 8
    assert thread.focal_index == 3
    assert {thread.role(i) for i in range(8)} == {rt.Role.FOCAL, rt.Role.AUTHOR}
    assert thread.root.id == "2117382378364522984"
    assert result.replies_from_others > 0
    assert any("--replies" in hint for hint in result.more)


def test_header_and_focal_marker() -> None:
    out = text(PATIO11_THREAD)
    assert out.startswith(
        "=== thread: 8 posts, focal is 4/8, 8 by the focal author · root @patio11"
    )
    assert "\n[4/8 ★ focal]\n" in out


def test_max_posts_marks_gaps_and_hints() -> None:
    result = report(PATIO11_THREAD, max_posts=4)
    assert result.shown == [0, rt.Gap(1, 3), 2, 3, 4, rt.Gap(3, 9)]
    assert "4 thread posts not shown: --max-posts 8" in result.more
    assert "[… 3 posts omitted …]" in rt.render(result)


def test_max_chars_never_clips_the_focal_post() -> None:
    result = report(PATIO11_THREAD, max_chars=40)
    entries = result.thread.entries
    assert entries[result.thread.focal_index].truncated_chars == 0
    assert all(e.truncated_chars for i, e in enumerate(entries) if i != 3)
    assert "some post text truncated: --max-chars 0" in result.more


def test_reply_into_someone_elses_thread() -> None:
    result = report(REPLY_INTO_THREAD, replies=3)
    thread = result.thread
    assert [thread.role(i) for i in range(5)] == [rt.Role.CONTEXT] * 4 + [rt.Role.FOCAL]
    assert any(
        "run on the root: https://x.com/simonw/status/2112630778068881543" in h for h in result.more
    )
    assert result.replies
    assert all(r.handle != "cipri_tom" for r in result.replies)
    assert not any("more replies" in hint for hint in result.more)  # all replies fetched
    assert "· other author]" in rt.render(result)


def test_single_post() -> None:
    out = text(FIRST_TWEET)
    assert out.startswith("=== single post (no parents, no self-replies) · root @jack")


# ---------------------------------------------------------------- quotes


def test_quote_chain_is_probed_for_the_focal_post(recorded: Recorded) -> None:
    result = report(QUOTE_CHAIN, recorded)
    quote = result.thread.focal.quote
    assert quote.handle == "Meffysto69"
    assert quote.quote is None
    assert quote.quote_ref.handle == "simonw"
    assert any(call.endswith("/2/status/2112908755654365220") for call in recorded.calls)
    assert "deeper quoted posts shown as links only: --quote-depth 2" in result.more


def test_quote_depth_two_expands_the_chain() -> None:
    quote = report(QUOTE_CHAIN, quote_depth=2).thread.focal.quote
    assert quote.quote.handle == "simonw"
    assert quote.quote.text


# ---------------------------------------------------------------- fallbacks


def test_parents_walk_when_thread_endpoint_fails() -> None:
    result = report(REPLY_INTO_THREAD, Recorded(fail=lambda url: "/2/" in url))
    thread = result.thread
    assert thread.source is rt.Source.PARENTS
    assert [e.id for e in thread.entries][-1] == REPLY_INTO_THREAD
    assert any("NOT fetched" in note for note in result.notes)
    assert result.replies_from_others is None


def test_capped_parent_walk_reports_root_not_reached() -> None:
    result = report(REPLY_INTO_THREAD, Recorded(fail=lambda url: "/2/" in url), max_posts=2)
    assert result.thread.root is None
    assert "root not reached" in rt.render(result)
    assert "parent walk stopped at 2: --max-posts 4" in result.more


def test_oembed_when_fxtwitter_is_down() -> None:
    result = report(PATIO11_THREAD, Recorded(fail=lambda url: "fxtwitter" in url))
    assert result.thread.source is rt.Source.OEMBED
    assert result.thread.focal.handle == "patio11"
    assert "thread context unknown" in rt.render(result)


def test_everything_down_is_a_failure() -> None:
    result = report(PATIO11_THREAD, Recorded(fail=lambda _url: True))
    assert isinstance(result, rt.Failure)
    assert "all sources down" in result.error


# ---------------------------------------------------------------- CLI


def test_cli_json_and_exit_status(recorded: Recorded) -> None:
    args = rt.parse_args(["--json", "--max-posts", "3", PATIO11_THREAD, "not-a-link"])
    output, status = rt.run(args, make_api(recorded))
    first, second = json.loads(output)
    assert status == 1
    assert first["focal_position"] == 4
    assert {"omitted": 1, "before_position": 3} in first["posts"]
    assert "quote_known" not in json.dumps(first)
    assert "error" in second


# ---------------------------------------------------------------- payload drift


def drift_thread(old: bytes, new: bytes) -> Recorded:
    """A fetcher whose /2/ payloads have `old` replaced by `new`."""
    return Recorded(rewrite=lambda url, body: body.replace(old, new) if "/2/" in url else body)


def test_renamed_field_falls_back_with_a_note() -> None:
    result = report(REPLY_INTO_THREAD, drift_thread(b'"author":', b'"user":'))
    assert result.thread.source is rt.Source.PARENTS  # not 5 bogus UNAVAILABLE posts
    (reason,) = result.thread.fallback_reasons
    assert "payload changed" in reason
    assert "missing required field `author`" in reason
    assert any(note.startswith("fell back because") for note in result.notes)


def test_changed_type_names_the_field() -> None:
    result = report(REPLY_INTO_THREAD, drift_thread(b'"likes": 4', b'"likes": "4"'))
    (reason,) = result.thread.fallback_reasons
    assert "Expected `int | null`, got `str`" in reason
    assert "likes" in reason


def test_drift_in_both_fxtwitter_apis_lands_on_oembed() -> None:
    drifted = Recorded(rewrite=lambda _url, body: body.replace(b'"author"', b'"user"'))
    result = report(PATIO11_THREAD, drifted)
    assert result.thread.source is rt.Source.OEMBED
    assert result.thread.focal.handle == "patio11"
    assert "payload changed" in result.thread.fallback_reasons[0]
    assert "oEmbed fallback" in rt.render(result)


def test_non_json_is_a_source_error() -> None:
    result = report(PATIO11_THREAD, Recorded(rewrite=lambda _url, _body: b"<html>blocked</html>"))
    assert isinstance(result, rt.Failure)
    assert "non-JSON response" in result.error
