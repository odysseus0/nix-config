# Facts more than one module needs, declared once. Public on purpose: the
# tailnet ACL, not obscurity, decides who reaches these.
{
  # The name and email commits carry, in git and jj alike.
  identity = {
    name = "tengjizhang";
    email = "odysseus0@users.noreply.github.com";
  };

  sietch = {
    host = "sietch.tail99865c.ts.net";
    beadsPort = 3307;
  };
  # The shared Beads board on Sietch's Dolt server.
  beads = {
    database = "beads";
    projectId = "3e01e0a5-1e41-43d6-b5e9-babe08cd9736";
  };
}
