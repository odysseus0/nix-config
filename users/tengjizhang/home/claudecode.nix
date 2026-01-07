{ ... }:

{
  #---------------------------------------------------------------------
  # Claude Code - AI coding assistant configuration
  #---------------------------------------------------------------------

  home.file = {
    ".claude/skills".source = ../claude/skills;
    ".claude/commands".source = ../claude/commands;
    ".claude/output-styles".source = ../claude/output-styles;
    # settings.json intentionally not managed - Claude CLI needs to mutate it
  };
}
