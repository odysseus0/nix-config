---
name: slack-format
description: "Format messages for Slack using mrkdwn syntax. Use when: (1) Writing or drafting a Slack message, (2) Converting markdown to Slack format, (3) User asks to 'format for Slack' or 'Slack message', (4) Copying text to clipboard for Slack."
---

# Slack mrkdwn Format

Slack uses "mrkdwn" - NOT standard markdown.

## Quick Reference

| Element | Slack mrkdwn | NOT this |
|---------|--------------|----------|
| Bold | `*text*` | `**text**` |
| Italic | `_text_` | `*text*` |
| Strike | `~text~` | `~~text~~` |
| Code | `` `code` `` | same |
| Block | ` ```code``` ` | same |
| Link | `<url\|text>` | `[text](url)` |
| Quote | `> text` | same |

## No Support

- Headers (`#`, `##`, etc.) - just use *bold*
- Nested lists
- Tables
- Images (use file uploads)

## Links

```
<https://example.com|Click here>
<mailto:hi@example.com|Email>
```

URLs auto-link: `https://example.com` works without formatting.

## Mentions

```
<@U012AB3CD>        User (by ID)
<#C123ABC456>       Channel (by ID)
<!here>             @here
<!channel>          @channel
<!everyone>         @everyone
```

## Escaping

Escape `&`, `<`, `>` in user content:

| Char | Escape |
|------|--------|
| `&` | `&amp;` |
| `<` | `&lt;` |
| `>` | `&gt;` |

## Lists

No special syntax - use plain text:

```
• Item one
• Item two
• Item three
```

Or with dashes: `- Item one`

## Output

When formatting for Slack, write directly to clipboard via:
```bash
cat /tmp/slack-msg.md | pbcopy
```
