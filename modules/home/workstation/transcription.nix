{ pkgs, ... }:
{
  home.packages = [ pkgs.local-transcription ];

  # Authored intent is immutable; uv writes only the adjacent .venv and its cache.
  xdg.dataFile."local-transcription/pyproject.toml".source = ../../../tools/transcription/pyproject.toml;
  xdg.dataFile."local-transcription/uv.lock".source = ../../../tools/transcription/uv.lock;
}
