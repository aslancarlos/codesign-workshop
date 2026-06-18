# Security Policy

## Scope & intent

This project is an **educational workshop**. It does not implement a signing
service; it drives an existing Code Sign Manager / PKCS#11 client to demonstrate
HSM-backed signing. It contains **no credentials, identities, tenants, or keys** —
all of that is supplied by the operator through environment variables.

## Handling secrets

- **Never commit secrets.** `KEYFILE` (service-account private key) and
  `API_TOKEN_FILE` (API key) point at secret material. `.gitignore` already
  excludes common secret patterns (`*.key`, `*.pem`, `*_token`, `.env`, …), but
  you remain responsible for what you stage.
- **The PKCS#11 PIN is a dummy.** `PKCS11_PIN` (default `1234`) is not a secret;
  with grant-based authentication the module ignores its value.
- **Generated artifacts.** The workshop writes signatures, a signed JAR, and a
  local session log (`signing_audit.log`) under `WORK`. The log contains the
  `IDENTITY` display name, tool names, artifact names, and SHA-256 hashes — no
  key material. Use the cleanup step when finished.
- **Grants.** Logging in stores a short-lived grant locally (handled by the
  vendor client). Use the workshop's logout/cleanup option to revoke it.

## Authorization

Only run this against tenants, projects, and keys you are **authorized** to use.
The workshop performs real signing operations that are recorded by the platform.

## Reporting a vulnerability

If you find a security issue in **this workshop script** (for example, a way it
could leak a secret it was given), please open a **private** report:

- Use GitHub's *"Report a vulnerability"* (Security Advisories) on the
  repository, or
- Open an issue **without** sensitive details and ask for a private channel.

Please do **not** include real keys, tokens, or tenant identifiers in any
report. For vulnerabilities in the underlying Code Sign Manager product or its
PKCS#11 client, contact the respective vendor.

We aim to acknowledge reports within a few business days.
