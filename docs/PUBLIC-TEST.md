# DANOS 2608 public test builds

These are **test builds for people who are comfortable with network operating
systems and can report what they see. They are not for production.**

## Download and verify

Images are published as pre-releases on the
[Releases page](https://github.com/i-danos/build-iso/releases). Each release has
the ISO, a `.sha256` file and the package list.

    sha256sum -c i-danos_2608_<timestamp>-amd64.hybrid.iso.sha256

After booting, `show version` should print
`DANOS (Lancaster) 2608 (DANOS:Shipping:2608:<date>)`.

## Try it

Boot the ISO (virtual machine or USB stick). The live session logs in as
`tmpuser` / `tmppwd`; this account exists only in the live session.

To install to disk, run `install image` and answer the prompts. The installer asks
you to choose the administrator user name and password; **no default password is
set on an installed system**. The first administrator account is not a superuser
until you run `set system login user <name> level superuser` and `commit`, then
log in again.

Dataplane interfaces start administratively down. Give one an address and enable
SSH to manage the box remotely:

    configure
    set interfaces dataplane <ifname> address <addr>/<len>
    set service ssh
    commit
    save

## Secure Boot

The boot chain is Microsoft-signed shim, then GRUB and the kernel signed by the
OBS project certificate. That certificate is not in any firmware database, so on a
machine with Secure Boot enabled it has to be enrolled once through MOK:

1. Download [`docs/secure-boot/danos-obs-signing.crt`](secure-boot/danos-obs-signing.crt).
2. Convert it: `openssl x509 -in danos-obs-signing.crt -outform DER -out danos-obs-signing.der`
3. Enroll it, either with `mokutil --import danos-obs-signing.der` on a Linux
   system installed on the same machine, or by copying the `.der` file to a
   FAT-formatted USB stick and choosing **Enroll key from disk** in the shim MOK
   manager. Reboot and confirm in the MOK manager screen.

Check the certificate before trusting it:

    SHA-256 fingerprint  8B:58:B9:3D:59:5C:1D:67:01:A5:82:6A:10:57:C2:8D:1B:58:36:62:40:B0:78:36:BC:0C:75:2C:3F:B8:09:DE
    Valid until          2028-10-29

The certificate expires on 2028-10-29, and GRUB SBAT revocations can stop older
images from booting.

## What was tested

* Robot suites (BGP, IPsec VPN, MPLS-LDP, firewall, REST, data-plane object model,
  BGP EVPN over VXLAN, IPv4 SSM and IPv6 multicast):
  98 of 98 pass on QEMU (the published pre-release was tested at 81 of 81, before
  the BGP EVPN and multicast suites were added). Disk install, upgrade and rollback, power-loss recovery
  and a Secure Boot chain (OVMF virtual firmware) were also exercised.
* Real hardware: Celeron J1900 with Intel I211 (four ports), OSPF and BGP between
  two boxes, QoS shaping, forwarding at about 940 Mbit/s TCP, same-version
  upgrade and rollback.
* Link failure: traffic forwarded through the data plane switches to the backup
  path in about one second. A downstream FRR patch removes the delay in the
  kernel routing table that used to affect traffic the router itself originates
  (12 of 12 link-down cycles clean on the test bench, 81 of 81 Robot cases on the
  patched image).

## Known limitations

* Verified only on QEMU and on J1900 / I211. Multi-queue / RSS, IOMMU / VFIO,
  hardware offload and SR-IOV are not verified. Scale and long-duration behaviour
  are not tested.
* Small-packet forwarding is slow: about 0.22 Mpps for 64-byte packets, roughly 15 %
  of line rate on the test hardware.
* Link-failure results come from two J1900 boxes joined by one cable: software
  interface-down cycles and two rounds of real cable pulls (15 of 15 clean after
  the FRR patch). One cable, one NIC family; other hardware is not covered.
* DMVPN (NHRP over multipoint GRE) does not work. Multipoint GRE tunnels come up,
  but an NHRP registration is returned to the sender by the data plane before it
  is encapsulated, so a spoke can never register with its hub. `nhrpd` is not
  started on the image and DANOS has no NHRP configuration. Point-to-point GRE,
  IPsec, VXLAN and MPLS are unaffected. Details and the two candidate fixes:
  `toolkit/docs/DEFECT-nhrp-mgre-slowpath.md`.
* No upgrade from DANOS 2105. Install fresh and migrate the configuration; the
  2105 administrator password cannot be exported and has to be set again.
* Secure Boot behaviour with a firmware revocation list (dbx) is not tested, and
  the IOMMU requirement for Secure Boot could not be tested on hardware without
  VT-d.
* The data-plane object view reports drift between the routing control plane and
  the data plane; it does not repair it.
* The test-harness account `tmpuser` exists on the live image only.

## Reporting problems

Open an issue on this repository with the image name, `show version` and what you
did. For anything that looks like a security problem use the private reporting
described in [SECURITY.md](../SECURITY.md). Licensing and source availability are
in [LICENSING.md](../LICENSING.md).
