---
name: obsidian
description: Obsidian vault formatting conventions. Use when writing notes to the vault, creating markdown files in Obsidian, or when format/syntax questions arise. Covers YAML frontmatter, wikilinks, and file structure.
---

# Obsidian Format

Conventions for the vault at `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/main/`.

## Note Structure

```markdown
---
tags:
  - tag1
  - tag2
---

# Title

Content here.

## Sources
- (Author, Year) for claims
```

## Conventions

**Frontmatter:** YAML with 3-7 specific tags

**Links:** Inline wikilinks `[[Note Title]]` or `[[Note Title|display text]]`
- No separate "Related Notes" section - links belong in context

**Sources:** Inline attribution (Author, Year), full references in ## Sources section for numerical claims and research

**Evergreen location:** `2_Knowledge/0_Evergreen/`

## File Hygiene

- Check CLAUDE.md in each folder for placement guidance
- Never create folders without explicit approval
- Prefer existing structure over new organization
