---
description: Reflect on session to identify system improvements, optionally focusing on specific aspects
---

# /improve-system $ARGUMENTS

## Purpose
Reflect on the current work session to identify system-level improvements that would help future sessions run more smoothly. Focus on patterns, not one-off misunderstandings. When arguments are provided, focus the analysis on the specified area. Ultrathink.

## What This Command Does
1. **Reviews the session** - Examines what went wrong or could have been better
2. **Distinguishes pattern types** - Separates system-level patterns from instance-specific confusion
3. **Identifies improvement locations** - Determines which context files could prevent similar issues
4. **Discusses changes** - Proposes specific improvements for discussion
5. **Helps implement** - After agreement, assists in updating the relevant files

## Key Principles
- **Be selective** - Not every mistake needs a system rule. Avoid over-systematizing.
- **Be intelligent** - Use reasoning to determine what's truly a pattern vs what was contextual ambiguity
- **Apply proper scope** - Improvements should live at the narrowest appropriate level:
  - Command-specific issues → command description
  - Folder-specific patterns → folder README or CLAUDE.md
  - Project patterns → project-level context
  - User-wide preferences → user system prompts
- **Be specific** - Suggest concrete improvements to specific files, not vague principles
- **Principle density** - High-level principles over session-specific examples. Maximum guidance per word.

## Usage Flow
1. User invokes `/improve-system` after a work session
   - Without arguments: Reviews entire session for patterns
   - With arguments: Focuses on specific aspect mentioned (e.g., `/improve-system focus on daily notes` or `/improve-system look at todo management`)
2. Assistant reviews the conversation for system-level patterns (either broadly or focused on specified area)
3. Assistant proposes specific improvements with proper scope
4. Discussion of which improvements are worth implementing
5. Assistant helps draft updates to the appropriate files
6. User approves and applies changes

## Remember
This is about making the system gradually better through actual use. Focus on patterns that will genuinely help future sessions. Always apply improvements at the narrowest appropriate scope.
