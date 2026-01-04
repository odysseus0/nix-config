---
name: blog-management
description: Personal blog management with Eleventy and Cloudflare Workers. Use when user mentions blog, publishing posts, blog deployment, tj-zhang.com, or writing articles for the blog. Covers content workflow from Obsidian to published post.
---

# Blog Management

Eleventy static blog hosted on Cloudflare Workers.

## Quick Reference

**Repository:** `~/projects/tj-zhang-blog/`
**Live Site:** [tj-zhang.com](https://tj-zhang.com)
**Deploy:** `pnpm ship`

## Content Creation Workflow

### From Obsidian to Blog

1. **Write in Obsidian** with full markdown structure:
   ```markdown
   # Article Title

   Tagline or subtitle

   Content...
   ```

2. **Copy to blog:**
   ```bash
   cp "obsidian/article.md" ~/projects/tj-zhang-blog/content/blog/new-post.md
   ```

3. **Edit for blog format:**
   - Add frontmatter with title, description, date, tags
   - **Remove H1 header** (template handles title display)
   - Keep tagline and content

4. **Final format:**
   ```markdown
   ---
   title: "Article Title"
   description: "Brief description"
   date: 2025-09-04
   tags: ["tag1", "tag2"]
   ---

   Tagline or subtitle

   Content...
   ```

5. **Deploy:**
   ```bash
   cd ~/projects/tj-zhang-blog && pnpm ship
   ```

## Why No H1 in Markdown

- Industry standard (Dan Abramov, Kent C. Dodds style)
- Single source of truth: title from frontmatter only
- Template handles title rendering
- No duplicate H1 headers

## Architecture

- **Eleventy:** Static site generation
- **Cloudflare Workers:** Hosting with global CDN
- **Local builds:** Faster than CI/CD for single-author blog
