---
name: twitter
description: X/Twitter via bird CLI. Use when user mentions Twitter, X, tweeting, posting tweets, reading tweets, mentions, bookmarks, or social media posting. Handles auth automatically via browser cookies.
---

# Twitter

X/Twitter access via `bird` CLI.

## Account

```
@odysseus0z
```

## Reading

```bash
# Read a tweet (ID or URL)
bird read <tweet-id-or-url>
bird <tweet-id-or-url>  # shorthand

# Get replies to a tweet
bird replies <tweet-id-or-url> -n 10

# Full conversation thread
bird thread <tweet-id-or-url>

# Search tweets
bird search "query" -n 10
bird search "from:elonmusk AI" -n 5
```

## Posting

```bash
# Post a tweet
bird tweet "Hello world"

# Reply to a tweet
bird reply <tweet-id-or-url> "My reply"

# Tweet with media (up to 4 images or 1 video)
bird tweet "Check this out" --media /path/to/image.png
bird tweet "Multiple" --media img1.png --media img2.png
```

## Engagement

```bash
# View mentions
bird mentions -n 10

# View bookmarks
bird bookmarks -n 10

# Remove bookmark
bird unbookmark <tweet-id>

# View likes
bird likes -n 10
```

## Following

```bash
# Who you follow
bird following -n 20

# Your followers
bird followers -n 20

# Lists
bird lists
bird list-timeline <list-id> -n 10
```

## Output Options

```bash
# JSON output (for parsing)
bird read <id> --json

# Plain text (no emoji/color)
bird mentions --plain
```

## Notes

- Auth uses browser cookies (Chrome/Firefox/Safari) - no API keys needed
- Use `bird check` to verify credentials
- Use `bird whoami` to see logged-in account
- Tweet IDs: numeric ID or full URL both work
