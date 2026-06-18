# Architecture

This document describes the data flow and the identity/authorization model that
the workshop demonstrates.

## Components

- **Signing tool** — `jarsigner`, `openssl`, or the client's own `pkcs11config`.
  Runs on the build/CI machine. Never holds private key material.
- **PKCS#11 module** — the vendor library (e.g. `venafipkcs11.so`) that
  implements the PKCS#11 API and forwards operations to the cloud service. For
  `jarsigner` it is loaded through Java's `SunPKCS11` provider; for `openssl`
  through the `pkcs11` engine.
- **Cloud Code Sign Manager (SaaS)** — enforces policy/approval, brokers access,
  and performs the signing inside an **HSM**.
- **HSM** — holds the private keys. Keys are generated/stored such that they are
  **non-extractable** (`CKA_EXTRACTABLE=false`) on a write-protected token.

## Signing data flow

```
   ┌────────────┐              ┌──────────────┐              ┌────────────┐
   │  tool      │ ─(1)──────>  │ PKCS#11 .so  │ ─(2)──────>  │  Cloud HSM │
   │ jarsigner/ │ <──────(4)─  │  (module)    │ <──────(3)─  │ [priv key] │
   │ openssl    │              └──────────────┘              └────────────┘
   └────────────┘
   (1) the tool hashes the artifact locally (e.g. SHA-256)
   (2) the module calls C_Sign(hash); the grant authenticates the session
   (3) the HSM returns the signature — the private key never leaves
   (4) the tool assembles the final signed object (JAR block, CMS envelope, ...)
```

The crucial property: **only the hash travels up, only the signature travels
down.** The private key stays inside the HSM at all times.

## Identity & authorization model

```
   Tenant
   └── Project ("my-project")
       ├── Owner            ── manages the project, but CANNOT sign
       ├── Authorized Signer ── may use the signing keys
       │     ├── Team (members)        → user identities
       │     └── Service Account       → machine identity (CLIENT_ID + key)
       └── Signing Keys
             ├── signing-key  (status: Ready)   → certificate + keypair in HSM
             └── ...
```

Key facts the workshop proves:

- **Owner ≠ Signer.** A tenant administrator who *owns* a project does not
  automatically see its keys. The client `list` returns nothing for an identity
  that is not an authorized signer.
- **Authorized signers** (a team member or a service account added to the
  project) receive *references* to the keys and can sign.
- **Grant-based auth.** The client exchanges its credential (service-account key
  or API key) for a short-lived grant. The PKCS#11 PIN is a dummy because the
  grant — not the PIN — authenticates the session.

## Authentication options

| Identity type | Credential | Typical use |
|---------------|-----------|-------------|
| Service account | `CLIENT_ID` + private key (PEM) | CI/CD, automation (recommended) |
| User | API key | interactive, admin/inventory queries |

## What the workshop reads from the API

When `API_TOKEN_FILE` is configured, the workshop issues read-only GraphQL
queries to `"$API_BASE/graphql"` to display:

- `codeSignProjects` → project name, owners, authorized signers
- `codeSignSigningKeys` → key name, status, project, `statistics.totalSignings`

Detailed activity/audit-log endpoints are intentionally **not** required: they
are commonly access-restricted, so the workshop keeps its own local session log
and points to the platform console for the authoritative audit trail.
