---
name: read-tweet
description: Read X/Twitter posts from their URLs without login or API key, with the surrounding thread pulled in automatically (parent chain, the author's self-thread above and below, quoted posts, media, stats; replies from others on request). Use when the user shares an x.com / twitter.com / fxtwitter / vxtwitter / xcancel status link, or refers to a specific post or thread you need to read. Cannot search X or read timelines, so ask the user for a link.
---

# Read a tweet (and its thread)

```sh
~/.agents/skills/read-tweet/scripts/read-tweet <url-or-id> [more ...]
```

Takes any URL containing `/status/<id>` (query strings and `/photo/1` are fine) or a bare numeric ID. Several posts can go in one call. It exits 1 if any post failed; the others still print.

You don't need to ask whether something is a thread. Every post comes back in context: the reply chain up to the conversation root, plus the focal author's own self-thread both **above and below** the linked post, in order. Any post in the thread works as the link.

## Reading the output

- The `===` header gives the shape, e.g. `thread: 8 posts, focal is 4/8, 8 by the focal author`, the root post, and the source used.
- Each post is tagged `[i/N]`. `★ focal` is the linked post, which is never truncated. `· other author` marks parent posts by someone else.
- `> quoting:` is an expanded quoted post. `> quoting @x: URL (not expanded)` means the quote chain goes deeper. This is always checked for the focal post; for other posts it shows only when the API includes it.
- Media lines (`[photo]`, `[video]`, `[gif]`) give direct URLs, plus alt text or the video's thumbnail. When the content of an image matters, fetch it and look.
- `note:` lines report gaps: root missing, posts unavailable, a fallback source and why (`fell back because …`, including a source whose payload changed shape).
- `more:` lines list what was left out and the exact flag that fetches it. Re-run with that flag only if the task needs it.

## Defaults and flags

| Flag | Default | Effect |
|---|---|---|
| `--max-posts N` | 30 | Thread posts shown: the root plus the posts nearest the focal one. Gaps print as `[… K posts omitted …]`. `0` = all. |
| `--max-chars N` | 2000 | Per-post text cap, except the focal post. Image alt text is capped at 300. `0` = no cap. |
| `--quote-depth N` | 1 | Levels of quoted posts to expand. |
| `--replies N` | 0 | Also fetch the top N replies by **other people** to the focal post, ranked by likes. |
| `--json` | | Structured output with the same fields, plus `omitted`, `notes` and `more` arrays. |

Replies from other people are **not** included by default. The header and `more:` give an approximate count. Fetch them with `--replies` when the reaction matters, e.g. the user asks how people responded.

If the linked post is someone's reply into another author's thread, you get the chain above it only. `more:` gives the root URL to run for the original author's full thread.

## Getting the link from the user

The script can't search, so "that tweet from @foo about bar" isn't enough. Ask for a link. Desktop: share icon → **Copy link**, or click the timestamp. Phone app: share icon → **Copy link**. For a thread, any one post's link is enough. If the output says posts after this one were NOT fetched, ask for the thread's **last** post.

## Limits

- Runs through `uv run --script` (PEP 723), so `uv` must be on PATH. The first run fetches Python 3.14+ and `msgspec` into uv's cache.
- Only posts that are visible while logged out. Protected, deleted, and some age-restricted posts fail.
- Sources: `api.fxtwitter.com` is unofficial and gives threads, media, quotes and stats. If its thread endpoint fails, the script falls back to walking parents only, with nothing below the linked post. The last resort is X's official oEmbed: plain text only, no thread context, and quotes appear as `t.co` links.
- No search, timelines, profiles or likes. Those need the paid X API. Say so rather than scraping x.com.
