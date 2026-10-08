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

The build scripts, workflows and documentation in `build-iso` and `toolkit` do not
yet have a top-level license file; the project owner has not chosen one. Files that
carry their own license header keep it (for example the Robot suites under
`tests/` are `LGPL-2.1-only`). Until a license file is added, do not assume any
license for the original scripts beyond what a file's own header says.
