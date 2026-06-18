# Code Signing Workshop (PKCS#11 → Cloud HSM)

An interactive, menu-driven terminal **workshop** that demonstrates, live, how
**HSM-backed code signing** works through the **PKCS#11** interface against a
cloud Code Sign Manager service (such as **CyberArk Code Sign Manager – SaaS**,
formerly *Venafi CodeSign Protect*).

The whole point of the workshop is to **prove**, step by step, the security
properties that matter when you sign software:

- 🔒 **The private key never leaves the HSM.** Tools send only a *hash*; the
  signature comes back. The workshop even tries to export the key and shows the
  HSM rejecting it.
- ✍️ **Real, verifiable signatures.** It signs a real `.jar` with `jarsigner`
  and produces a real CMS/PKCS#7 signature with `openssl`, then verifies both
  with their native tooling.
- 👥 **Separation of duties.** Being a project *owner* does **not** grant signing
  access — only an *authorized signer* identity can use the keys.
- 🧾 **Governance & non-repudiation.** It pulls the per-key signature counter
  from the platform API and keeps a local, detailed log of every signature it
  performs (timestamp, identity, key, tool, artifact, SHA-256).

The interactive UI is available in **Portuguese (pt)** and **Spanish (es)**.
This documentation is in English.

> ⚠️ **Disclaimer.** This is an **educational / demo** tool. It is **not**
> affiliated with, endorsed by, or supported by CyberArk or Venafi. All product
> names are trademarks of their respective owners. Use it only against tenants
> and keys you are authorized to access.

---

## Table of contents

- [How it works](#how-it-works)
- [Requirements](#requirements)
- [Configuration](#configuration)
- [Running the workshop](#running-the-workshop)
- [The steps](#the-steps)
- [Architecture](#architecture)
- [Security notes](#security-notes)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## How it works

Signing tools on the build machine talk to a **PKCS#11 module** (the Code Sign
Manager client library, e.g. `venafipkcs11.so`). That module forwards a hash to
the cloud service, which performs the signing operation inside an **HSM** and
returns the signature. The private key material is never present on the client.

```
   build machine                 PKCS#11 module            Cloud HSM
   (jarsigner/openssl)  ──hash──►  (vendor .so)   ──hash──►  [ private key ]
                        ◄─sig───                  ◄─sig────   🔒 never leaves
```

Identities authenticate to the service with a **grant** (obtained via the
client's `login`). Keys only become visible to identities that are **authorized
signers** on a project that contains signing keys.

## Requirements

The workshop is a portable `bash` script. To exercise **every** step you need:

| Tool | Used for | Required |
|------|----------|----------|
| `bash` (4+) | the workshop itself | ✅ |
| A Code Sign Manager **PKCS#11 client** (provides `pkcs11config` + the `.so`) | login, list, sign, getcertificate | ✅ |
| `openssl` (3.x) with the **pkcs11 engine** (`libpkcs11.so` / `engines-3/pkcs11.so`) | CMS signing & verification | optional step |
| `jarsigner` + `keytool` (JDK 11+) | real JAR signing & the "key stays in HSM" proof | optional steps |
| `python3` | formatting the API/inventory output | optional steps |
| `curl` | API-backed steps (counts, signers) | optional steps |

If a tool is missing, the corresponding step degrades gracefully with a note;
the rest of the workshop still runs.

> The PKCS#11 client and the cloud tenant are **not** provided by this project.
> You bring your own. See [Configuration](#configuration).

## Configuration

Everything is configured through **environment variables** — there are no
hardcoded identities, keys, tenants, or labels. Copy the template and adjust:

```bash
cp .env.example .env
# edit .env, then:
set -a; . ./.env; set +a
./codesign-workshop.sh
```

| Variable | Default | Description |
|----------|---------|-------------|
| `CLIENT_ID` | *(empty)* | Service account UUID used for login (required for the login step) |
| `KEYFILE` | `$HOME/.codesign/service_account.key` | Service account private key (PEM) |
| `API_TOKEN_FILE` | `$HOME/.codesign/api_token` | File containing an API key; enables the API-backed steps |
| `LABEL_SIGN` | `signing-key` | Signing key label (as shown by `pkcs11config list`) |
| `LABEL_CERT` | `$LABEL_SIGN` | Certificate label to download |
| `PROJECT` | `my-project` | Code Sign project name (used in API queries and console hints) |
| `IDENTITY` | `signer` | Friendly display name for the signing identity |
| `TENANT` | *(empty)* | Tenant / URL prefix (only shown in console hints when set) |
| `API_BASE` | `https://api.venafi.cloud` | API region base URL (US default; EU/AU/UK/SG/CA differ) |
| `BRAND` | `Machine Identity - Code Signing Workshop` | Banner / title text |
| `MODULE` | `/opt/venafi/codesign/lib/venafipkcs11.so` | Path to the PKCS#11 module |
| `ENGINE_SO` | `/usr/lib/x86_64-linux-gnu/engines-3/pkcs11.so` | Path to the OpenSSL pkcs11 engine |
| `PKCS11_PIN` | `1234` | PKCS#11 PIN — a dummy value; the real auth is the cloud grant |
| `WORK` | `/tmp/codesign_demo` | Working directory for generated artifacts |
| `DEMO_LANG` | *(ask)* | `pt` or `es`; if empty the workshop asks at startup |

> **The `PKCS11_PIN` is intentionally a dummy.** With grant-based
> authentication the module ignores the PIN value, but the PKCS#11 spec still
> requires *a* login. This is itself a teaching point in the workshop.

## Running the workshop

```bash
./codesign-workshop.sh            # asks for language, then shows the menu
DEMO_LANG=es ./codesign-workshop.sh   # start directly in Spanish
```

Pick steps from the menu, or press **`g`** to run the full guided script
(opening → value recap). Press **`l`** to switch language on the fly.

## The steps

| # | Step | What it demonstrates |
|---|------|----------------------|
| i | Opening | The business problem + architecture diagram |
| 1 | Prerequisites | Client version and grant validity |
| 2 | Login | Authenticate as a service account (machine identity) |
| 3 | Separation of duties | Owner sees nothing; authorized signer sees the keys |
| 4 | List | Key/cert references synced to the client |
| 5 | Key stays in HSM | Export attempt is **rejected** (non-extractable) |
| 6 | Get certificate | Download the public cert + chain only |
| 7 | Sign a JAR | Real `jarsigner` signature, verified natively |
| 8 | Sign CMS/PKCS#7 | Real `openssl` signature + round-trip latency |
| 9 | Integrity & tampering | Positive verify + tamper detection |
| 10 | Governance | Central key inventory + signers via the API |
| 11 | Signatures & logs | Per-key counter + last 5 detailed signing records |
| 12 | Value recap | Proof points + compliance mapping |

Each signing step (7, 8, 9) prints an **ASCII flow diagram** of how the tool
reaches the HSM through PKCS#11, and appends a record to a local session log
shown in step 11.

## Architecture

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the data-flow diagrams and
the identity/authorization model.

## Security notes

See [`SECURITY.md`](SECURITY.md). In short: never commit private keys or API
tokens; the workshop writes generated artifacts (and a session signing log that
contains a service-account display name and artifact hashes) under `WORK` — clean
it up with the menu's *cleanup* option when you're done.

## Troubleshooting

See [`docs/USAGE.md`](docs/USAGE.md#troubleshooting). The most common issue is an
empty `list`: that means the authenticated identity is **not an authorized
signer** of a project that contains *ready* keys — fix it in the console, then
re-login with `--force`.

## Contributing

Contributions are welcome — see [`CONTRIBUTING.md`](CONTRIBUTING.md) and the
[`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).

## License

[MIT](LICENSE).
