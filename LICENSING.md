# Licensing and source availability

An image built from this repository is a Debian 13 (trixie) system plus the DANOS
packages. It is a collection of separately licensed works, not a single program
under a single license.

## What is in an image

* **Debian packages** keep their Debian licenses. Each installed package ships its
  license text at `/usr/share/doc/<package>/copyright` inside the image.
  Debian publishes the corresponding source at <https://deb.debian.org/debian/>
  (`deb-src`).
* **DANOS packages** (for example `vyatta-dataplane`, `vyatta-cfg`, `vyatta-op`
  and the other packages built in the OBS project `home:i-danos`) carry the
  licenses stated in each package's `debian/copyright`, which is also installed at
  `/usr/share/doc/<package>/copyright`. Check that file for the license of each
  package; do not assume one license for all of them.
* **Patched Debian packages**: `frr` is Debian's FRRouting 10.3 with one downstream
  patch (see `frr-patches/` in the toolkit repository). It stays under FRRouting's
  GPL-2.0-or-later license.

## Getting the source

The source packages (`.dsc`, `.orig.tar.*`, `.debian.tar.*`) for every DANOS package
in an image are public:

    https://api.opensuse.org/public/source/home:i-danos/<package>

The image build recipe is this repository. The test and release tooling is
<https://github.com/i-danos/toolkit>. Each image's `manifest.txt` and
`sbom.json` list the exact package versions it contains.

## Files in these repositories

`build-iso` is the DANOS live-build recipe and carried the upstream `LICENSE` file
until it was dropped by mistake when the recipe was retargeted at Debian 13; that
file is restored unchanged. It follows the DANOS convention: the repository uses
SPDX tags, and a file with no `SPDX-License-Identifier` tag, or with
`GPL-2.0-only`, is under the GNU GPL version 2. Files that carry another tag keep
it; for example the Robot suites under `tests/` are `LGPL-2.1-only`. The
`toolkit` repository follows the same convention and carries the same `LICENSE`.

New files should say which license they are under with an
`SPDX-License-Identifier:` line, as the upstream DANOS repositories do.
