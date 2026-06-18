# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- `step_cleanup`: replaced the `A && B || C` pattern with explicit `if/then/else`
  so the "kept" branch can never run after a successful action (ShellCheck
  SC2015). No user-visible behavior change.

### Changed

- Refactored the script into modules under `src/`, assembled into the
  single distributable `codesign-workshop.sh` by `build.sh`. No behavior change;
  the generated file is byte-equivalent to the previous one.

### Added

- `build.sh` (with a `--check` mode used by CI) to (re)generate and verify the
  distributable.
- CI now verifies the distributable is in sync with `src/` before linting.

## [1.0.0] - 2026-06-18

### Added

- Interactive, menu-driven workshop demonstrating HSM-backed code signing via
  PKCS#11 against a cloud Code Sign Manager service.
- Bilingual UI (Portuguese / Spanish) with on-the-fly language switching.
- Opening with business context and an architecture diagram.
- Step: login as a service account (machine identity).
- Step: separation of duties — owner vs. authorized signer.
- Step: list key/certificate references on the client.
- Step: proof that the private key never leaves the HSM (export is rejected).
- Step: download certificate + chain (public material only).
- Step: real JAR signing with `jarsigner` (SunPKCS11) and native verification.
- Step: real CMS/PKCS#7 signing with `openssl` (pkcs11 engine) + latency, and
  verification.
- Step: integrity & tamper detection (positive + negative verification).
- Step: governance — central key inventory and authorized signers via the API.
- Step: signatures & logs — per-key signature counter plus the last 5 detailed
  session signing records (timestamp, identity, key, tool, artifact, SHA-256).
- Step: value recap with compliance mapping.
- ASCII flow diagrams for each signing path and for the architecture.
- Fully environment-variable driven configuration; no hardcoded identities,
  keys, tenants, or labels.

[1.0.0]: https://keepachangelog.com/en/1.1.0/
