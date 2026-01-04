# /process-inbox

Extract value from raw brain dump into proper system locations.

## Core Question: Will this information be lost?

**Preserve explicitly when:**
- Contains non-obvious insight that emerged through experience/conversation
- Captures ephemeral context (who said what, why it mattered)
- Represents synthesis or pattern recognition
- Would lose meaning if reduced to action item

**Compress to reference when:**
- Information is retrievable (URLs, documentation)
- Implementation details that follow from intent
- Standard procedures that don't need special context

## The Extraction Principle

Inbox processing is about **preserving information entropy**:
- High entropy (unique, surprising, personal) → Expand to note
- Low entropy (predictable, standard, googleable) → Compress to todo

## The Completion Test

After processing: Could you reconstruct what mattered from what remains?
- Actions captured → Can execute
- Insights captured → Can build upon
- Context captured → Can remember why

If yes → Safe to delete source

## Process

1. Parse each line/item from the inbox
2. Apply entropy test to determine expand vs compress
3. Place in appropriate existing location (never create folders)
4. Verify all valuable information preserved
5. Confirm: "X todos added, Y notes created, safe to delete source"

## Core Principles

**Classification**: "Do I need to DO something?" → Project. "Is this understanding?" → Knowledge.

**Fidelity**: Preserve USER thinking, don't substitute ASSISTANT analysis. Basic cleanup only.

**References**: Use stable interfaces (`task list project:project-name`), never positional identifiers.

**Integration**: Project notes require matching project tags in tasks. Maintain bidirectional consistency.

## System Context

- Task format: @1_System/0_Core/Workflows/TaskManagement/system-description.md
- Folder structure: See CLAUDE.md in vault