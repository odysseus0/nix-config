# feed, an RSS CLI (github.com/odysseus0/feed): the one package here built
# from source: a small Go module whose SQLite driver is pure Go.
{ buildGoModule, fetchFromGitHub }:
buildGoModule {
  pname = "feed";
  version = "0-unstable-3f54d4b";
  src = fetchFromGitHub {
    owner = "odysseus0";
    repo = "feed";
    rev = "3f54d4b43f552ee05cd7422adf7d354405c53bad";
    hash = "sha256-m5pNblYp1HxfWODuwpF043Ez/o5iKNHBUVq/ioOIM9o=";
  };
  vendorHash = "sha256-gzPYgvxb9CBMZm7aX1ZWwjhQATY3e0dP7WEpv2Mhq14=";
  subPackages = [ "cmd/feed" ];
  doCheck = false;
}
