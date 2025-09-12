# ForgeOS — Implementation Plan (v0.1 → v0.4)

> Pragmatic, testable steps to turn the architecture into a bootable, updateable, secure edge OS. Each component includes **scope**, **tasks**, **artifacts**, and **verification**.

---

## 0) Project Bootstrap

**Scope**
- Initialize repo, pin versions, create Makefile + scripts, and local dev loop on Apple Silicon.

**Tasks**
- [ ] Create repo skeleton (`forgeos/`).
- [ ] Add `Makefile` targets: `toolchain`, `kernel`, `busybox`, `rootfs`, `initramfs`, `image`, `qemu-run`, `sign`, `release`.
- [ ] Provide scripts under `scripts/` for each stage.
- [ ] Add `.gitignore`, `LICENSE`, `README.md`.
- [ ] Optionally set up **Lima** VM for Linux host tools (mkfs.ext4, losetup).

**Artifacts**
- `Makefile`, `scripts/*`, `docs/build-on-macos.md`.

**Verification**
- `make qemu-run` boots to BusyBox shell on QEMU/HVF (macOS).

---

## 1) Toolchains (musl default, glibc optional)

**Scope**
- Deterministic cross toolchains for `aarch64` (and `x86_64` later).

**Tasks**
- [ ] `toolchains/musl/` using **musl-cross-make** (triplet: `aarch64-linux-musl-`).
- [ ] `toolchains/gnu/` using **crosstool-ng** or distro-provided `aarch64-linux-gnu-*` (optional for glibc track).
- [ ] Export env helpers: `env.musl`, `env.gnu` to set `CROSS_COMPILE`, `ARCH`, `PATH`.
- [ ] Pin versions (binutils, gcc, musl/glibc) in `toolchains/versions.mk`.

**Artifacts**
- `output/` toolchains (ignored by git), `toolchains/README.md`, `toolchains/versions.mk`.

**Verification**
- `$(CC) --version` emits pinned versions; `file` on produced binaries shows correct ELF/ABI; simple “hello world” cross-compiles and runs under QEMU.

---

## 2) Linux Kernel

**Scope**
- Minimal aarch64 kernel for `-M virt` and later board targets. Hardened defaults.

**Tasks**
- [ ] Add kernel as submodule (`kernel/`).
- [ ] Create `kernel/configs/aarch64_defconfig` enabling: initramfs, DEVTMPFS, VirtIO (blk/net), 9p (optional), AppArmor, seccomp, nftables, KASLR.
- [ ] `scripts/build_kernel.sh` with `make ARCH=arm64 Image modules dtbs`.
- [ ] Optional: `kernel/patches/` with local hardening or driver tweaks.
- [ ] Install artifacts to `artifacts/arch/arm64/boot/`.

**Artifacts**
- `Image`, `modules`, `dtbs`, saved `.config` checksum.

**Verification**
- QEMU boots to kernel, recognizes virtio devices; `zcat /proc/config.gz | grep CONFIG_APPARMOR=y` passes (if built-in).

---

## 3) Userland Base (BusyBox + overlay)

**Scope**
- Static BusyBox for tiny base; overlay for `/etc`, `init`, motd, skeleton users/groups.

**Tasks**
- [ ] Add BusyBox as submodule (`userland/busybox/`).
- [ ] `configs/busybox_defconfig` with `Build static` and applets (init, sh, mdev, udhcpc, ifconfig/ip, syslogd/klogd).
- [ ] `scripts/build_busybox.sh` (with `CROSS_COMPILE` from env).
- [ ] Create `userland/overlay-base/` (minimal `/etc`, `/etc/inittab`, `/etc/fstab`, `/etc/passwd`, `/etc/group`, `/etc/motd`).
- [ ] Add `rootfs skeleton`: `/proc`, `/sys`, `/dev`, `/var`, `/tmp`, `/run`, permissions and device nodes (`/dev/console`, `/dev/null`).

**Artifacts**
- `_install/` BusyBox staging, `overlay-base/`.

**Verification**
- `busybox` runs under QEMU; `ps`, `ifconfig`/`ip`, `mdev`, `udhcpc` available; login works on `ttyAMA0` (if configured).

---

## 4) Init Layer & Profiles

**Scope**
- `busybox init` (core-min), optional `openrc` or `systemd` (service-sd). Profile overlays + package lists.

**Tasks**
- [ ] **core-min profile:** `/etc/inittab`, `mdev` rules, `udhcpc` hook scripts, agetty on `ttyAMA0`.
- [ ] **service-sd profile (optional for v0.2):** integrate systemd: `systemd`, `systemd-networkd`, `systemd-resolved`, unit files for ssh, chrony, nftables.
- [ ] **profiles/** structure: each profile has `overlay/` and `packages.txt`.
- [ ] `scripts/apply_profile.sh` to merge overlay + packages into rootfs build.

**Artifacts**
- `profiles/core-min/`, `profiles/service-sd/` (later), docs/profiles.md.

**Verification**
- Switching profiles changes init system; `PID 1` is `init` or `systemd` accordingly; services come up as defined.

---

## 5) Package System (apk as default)

**Scope**
- Alpine-style `apk` repository for ForgeOS packages; signed indexes; simple package lists per profile.

**Tasks**
- [ ] Vendor or build `apk-tools` for target and host.
- [ ] Create local `apk` repo structure: `packages/$ARCH/` with `.apk` files.
- [ ] Generate and manage repo index (`apk index`), sign with `minisign`/`openssl` keys stored in `security/keys/`.
- [ ] Base package list (`busybox` is built-in; add `iproute2`, `chrony`, `dropbear/openssh`, `nftables`, `ca-certificates`).
- [ ] `scripts/build_apk.sh` for any custom packages.
- [ ] `scripts/mk_rootfs.sh` installs packages into rootfs using `apk --root` with your repo.

**Artifacts**
- `repo/` with signed `APKINDEX.tar.gz`, packages, rootfs with `/etc/apk/repositories` pointing to repo.

**Verification**
- Inside QEMU: `apk add curl` from your repo works; package signatures verified; `apk audit` clean.

---

## 6) Root Filesystem & Images

**Scope**
- Create initramfs and disk images (ext4, qcow2). Pivot-to-root supported.

**Tasks**
- [ ] `scripts/mk_initramfs.sh`: assemble from BusyBox + overlay(s); add `/init` with `switch_root` logic.
- [ ] `scripts/mk_disk.sh`: create `root.img` (ext4), mount (in Lima VM), populate with rootfs, set correct `/etc/fstab`.
- [ ] Add QEMU runtime helper `scripts/qemu_run.sh` to boot with `-initrd` or disk.
- [ ] Optional: ISO/EFI builder for x86_64 targets.

**Artifacts**
- `artifacts/initramfs.gz`, `artifacts/root.img`, `artifacts/forgeos.qcow2` (optional).

**Verification**
- QEMU boots with `-initrd` **and** boots with `-drive file=root.img`; persistent `/etc` and `/home` work across reboots.

---

## 7) Security Baseline

**Scope**
- Kernel hardening, nftables default policies, user separation, AppArmor profiles, secure mounts, package signing.

**Tasks**
- [ ] Kernel: enable KASLR, STACKPROTECTOR_STRONG, SECCOMP, APPARMOR; save `.config` in repo.
- [ ] AppArmor: provide base profiles for sshd, dropbear, chrony, update agent (`security/apparmor/`).
- [ ] nftables: `security/nftables/base.nft` with default-deny inbound and minimal egress.
- [ ] Mount options: `/tmp` as `tmpfs,noexec,nodev,nosuid`; `/var/log` size-limited.
- [ ] `scripts/sign_artifacts.sh`: cosign/minisign for images and repo index; store public keys under `/etc/forgeos/keys` at build.
- [ ] Non-root users for services; `doas` or `sudo` minimal policy.

**Artifacts**
- Kernel config, nftables rules, AppArmor profiles, signed packages/images, `docs/hardening.md`.

**Verification**
- `aa-status` shows loaded profiles; `nft list ruleset` matches baseline; mounting shows secure flags; package verification enforces signatures.

---

## 8) Networking

**Scope**
- DHCP client, static IP option, DNS, time sync, basic firewall, optional 9p share for dev loop.

**Tasks**
- [ ] BusyBox `udhcpc` script for lease events (write `/etc/resolv.conf`, bring up interface).
- [ ] `chrony` with minimal config; RTC fallback if present.
- [ ] nftables rules applied on boot.
- [ ] Optional dev convenience: QEMU `virtfs` (`-virtfs local,...`) and `/etc/fstab` entry for `/mnt/host` in lab profile.

**Artifacts**
- `/etc/network/if-up.d/*`, `/etc/chrony/chrony.conf`, `security/nftables/base.nft`.

**Verification**
- On boot, IP acquired; DNS resolves; NTP sync; firewall counters increment on expected chains.

---

## 9) Observability

**Scope**
- Logging + metrics minimal set, with optional forwarder.

**Tasks**
- [ ] core-min: BusyBox `syslogd`/`klogd`, log rotation in `/etc/newsyslog.conf` or custom cron/hourly script.
- [ ] service-sd: journald with forwarder (rsyslog or fluent-bit) to `/var/log`.
- [ ] Metrics: tiny node-exporter-like script (textfile) or `busybox top` exporter; expose on `:9100` (optional).
- [ ] Add `docs/observability.md` with log locations and commands.

**Artifacts**
- `/etc/*log*`, optional `/usr/local/bin/metrics-exporter`.

**Verification**
- Logs present and rotated; optional endpoint returns metrics; rate-limited logging confirmed.

---

## 10) Updates

**Scope**
- **Default**: apk-based updates with signatures. **Optionals**: RAUC A/B, OSTree track.

**Tasks (apk path)**
- [ ] `forgeos-update` script: refresh index, stage package set from `channel` (stable/edge), verify signatures, apply, reboot if needed.
- [ ] Add health checks (post-update smoke tests).

**Tasks (A/B path — later)**
- [ ] Integrate RAUC: create bundle recipe, sign with `rauc.key`, add bootloader hooks, slot switching logic, health checks.

**Tasks (OSTree — later)**
- [ ] Initialize OSTree repo; create commits for `/usr`; deploy with kernel/initramfs integration; rollback tooling.

**Artifacts**
- Update scripts, repo keys, RAUC/OSTree configs.

**Verification**
- Apk updates: package upgrade works and persists; rollback path documented; version string updated in MOTD; health checks pass.

---

## 11) Device Management

**Scope**
- Serial-first access; SSH optional; minimal agent (optional) for remote actions and metrics.

**Tasks**
- [ ] agetty on `ttyAMA0`; disable password login or set strong defaults.
- [ ] SSH: prefer key-only; disable root login; rate-limit via firewall.
- [ ] Optional `forgeos-agent` (simple HTTP/gRPC) sandboxed with seccomp + cgroups; limited command set.
- [ ] `docs/device-management.md` for provisioning keys, first-boot steps.

**Artifacts**
- getty config, sshd/dropbear config, agent binary (optional).

**Verification**
- Serial login works; SSH key auth works (password off); agent runs in sandbox and survives restarts.

---

## 12) Build Orchestration

**Scope**
- One-command builds, reproducibility, SBOM, checksums, signatures.

**Tasks**
- [ ] Root `Makefile` with phony targets and dependency graph.
- [ ] `SOURCE_DATE_EPOCH` exported; deterministic tar/gzip flags.
- [ ] SBOM: run `syft` on rootfs and produce `artifacts/sbom/*.json`.
- [ ] Checksums: `sha256sum` across artifacts; sign with cosign/minisign.

**Artifacts**
- `Makefile`, `artifacts/*`, `docs/release.md`.

**Verification**
- Rebuild twice yields identical SHA256 (or within reproducibility bounds); SBOM present; signatures verify with public keys.

---

## 13) CI/CD

**Scope**
- GitHub/GitLab pipelines to build, test, and release images for profiles/architectures.

**Tasks**
- [ ] CI matrix: `{profile} × {arch}` (start with `core-min × aarch64`).
- [ ] Cache heavy toolchain layers.
- [ ] Upload artifacts (Image, initramfs, root.img, qcow2, SBOM, checksums, signatures) to releases.
- [ ] Basic QEMU smoke test in CI (boot, run `uname -a`, `cat /etc/forgeos-release`).

**Artifacts**
- `.github/workflows/build.yml` or `.gitlab-ci.yml`.

**Verification**
- CI passes with artifacts downloadable; smoke boot test logs attached to job; release notes generated.

---

## 14) QEMU & Hardware Bring-up

**Scope**
- Reliable emulated dev loop; path to real devices (Pi 5, generic UEFI x86_64).

**Tasks (QEMU)**
- [ ] `scripts/qemu_run.sh` for initramfs-only and disk-root modes.
- [ ] `-accel hvf` on macOS; `-nographic -serial mon:stdio`; `-append "console=ttyAMA0"`.
- [ ] Optional: `-virtfs` mount for host ↔ guest file share in lab profile.

**Tasks (Hardware — later)**
- [ ] Raspberry Pi 5: integrate appropriate boot firmware/U-Boot; kernel DT overlays; rootfs on SD/eMMC; `cmdline.txt` and `config.txt`.
- [ ] x86_64 UEFI: GRUB + EFI stub, ISO builder, secure boot keys (optional).

**Artifacts**
- `scripts/qemu_run.sh`, `docs/hardware.md`, board-specific overlays.

**Verification**
- QEMU boots consistently; for hardware, device enumerates NIC/storage; serial console usable; networking up.

---

## 15) Documentation & Developer UX

**Scope**
- Clear docs for build, profiles, security, updates, and troubleshooting.

**Tasks**
- [ ] `docs/architecture.md` (already drafted), `build-on-macos.md`, `profiles.md`, `hardening.md`, `observability.md`, `device-management.md`, `release.md`, `troubleshooting.md`.
- [ ] Copy-paste-friendly commands; known-good versions cited.
- [ ] MOTD displays profile, kernel, toolchain triplet, update channel.

**Artifacts**
- Markdown docs in `docs/`.

**Verification**
- New contributor can clone → `make qemu-run` → see shell within minutes; can switch profiles per docs.

---

## 16) Milestones

**v0.1 — Bootable Core**
- Boots in QEMU to BusyBox shell (`core-min`).
- DHCP works; optional SSH; nftables baseline; signed apk repo; `forgeos-update` basic.
- CI builds aarch64 artifacts; SBOM + signatures published.

**v0.2 — Profiles & Hardening**
- Add `service-sd` profile with systemd.
- AppArmor base profiles; improved firewall; docs expanded.

**v0.3 — Transactional Updates (optional track)**
- RAUC A/B or OSTree based image updates; health checks and rollback.

**v0.4 — Edge Integrations**
- IoT gateway profile (OPC UA→MQTT), metrics/log forwarding, minimal agent with seccomp.


---

## 17) Acceptance Checklists (Roll-up)

- [ ] `make qemu-run` (initramfs) and (disk-root) work on macOS/HVF.
- [ ] `apk add` from signed repo works; packages verified.
- [ ] nftables default-deny inbound; time sync OK; SSH key-only (if enabled).
- [ ] AppArmor loaded; select services confined.
- [ ] Reproducible builds (hashes stable within tolerances); SBOM generated; artifacts signed.
- [ ] CI publishes artifacts and passes a headless boot smoke test.
