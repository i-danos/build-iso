# Security policy

DANOS 2608 images published from this repository are **public test builds**, not
production releases (see [docs/PUBLIC-TEST.md](docs/PUBLIC-TEST.md)).

## Reporting a vulnerability

Please do not open a public issue for a security problem.

Use GitHub's private reporting: on this repository open **Security → Report a
vulnerability**. Include the image name and `show version` output, what you did,
and what you saw. We will acknowledge the report and tell you whether we can
reproduce it.

Problems in an upstream component (Debian, FRRouting, the Linux kernel, VPP/DPDK,
strongSwan and so on) are best reported to that project as well; tell us which
DANOS build you found it in so we can pick up the fix.

## What is in scope

* The image build recipe and scripts in this repository.
* Packages built from `home:i-danos` on OBS and shipped in the image.
* The signing and Secure Boot chain described in
  [docs/PUBLIC-TEST.md](docs/PUBLIC-TEST.md#secure-boot).

## Supported versions

Only the most recent public test build receives fixes. Builds are not backported.
