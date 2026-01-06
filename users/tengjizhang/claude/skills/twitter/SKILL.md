---
name: twitter
description: X/Twitter via bird CLI. Use when user mentions Twitter, X, tweeting, posting, reading tweets, mentions, or bookmarks. (user)
---

# Twitter

`bird` CLI for X/Twitter. Account: @odysseus0z

Runs via `pnpm dlx` from personal fork — auto-updates on new commits.

## Quick Reference

```bash
bird tweet "text"              # post
bird reply <url> "text"        # reply
bird read <url>                # read tweet (full article body)
bird search "query" -n 10      # search
bird mentions -n 10            # mentions
bird bookmarks -n 10           # bookmarks
bird home -n 20                # home timeline (personal fork)
bird home --following -n 20    # following-only timeline
```

## Output Features (Personal Fork)

**Article tweets** display intelligently:
- In feeds/search: Shows title + preview text
- Via `bird read`: Shows full article body

**Quote tweets** show nested content:
```
┌─ QT @quoted_user:
│  Quoted content here...
│  🖼️ https://pbs.twimg.com/media/image.jpg
└─ https://x.com/quoted_user/status/123
```

**Media** shows with type indicators:
- 🖼️ photo
- 🎬 video
- 🔄 animated gif

## Also Supports

- Threads and conversation views
- Media attachments (images, video)
- Following/followers lists
- Twitter lists and list timelines
- Likes management
- JSON output (`--json`) for parsing

Run `bird --help` for full syntax.
