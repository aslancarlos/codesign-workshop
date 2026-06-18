# Usage

## Prerequisites checklist

1. A working **Code Sign Manager PKCS#11 client** on the machine
   (`pkcs11config` on the `PATH`, and the module at `MODULE`).
2. A **service account** authorized as a *signer* on your project, with its
   private key file (`KEYFILE`) and UUID (`CLIENT_ID`).
3. (Optional) An **API key** in `API_TOKEN_FILE` to enable the inventory/counter
   steps.
4. (Optional) `jarsigner`/`keytool` (JDK) and `openssl` with the `pkcs11` engine
   for the real-signing steps.

## Configure

```bash
cp .env.example .env
$EDITOR .env
set -a; . ./.env; set +a
```

## Run

```bash
./codesign-workshop.sh
```

- The workshop asks for a language (Portuguese / Spanish) unless `DEMO_LANG` is
  set.
- Choose individual steps by number, or **`g`** for the full guided run.
- **`l`** toggles the language; **`d`** runs diagnostics; **`c`** cleans up.

### One-off overrides

```bash
DEMO_LANG=es BRAND="ACME · CodeSign Lab" IDENTITY="ci-signer" \
  PROJECT="acme-prod" LABEL_SIGN="release-key" ./codesign-workshop.sh
```

## Real-signing steps in detail

### JAR (`jarsigner` + SunPKCS11)

The workshop writes a temporary `SunPKCS11` config pointing at `MODULE`, then:

```bash
jarsigner -keystore NONE -storetype PKCS11 \
  -providerClass sun.security.pkcs11.SunPKCS11 -providerArg <p11.cfg> \
  -storepass <PKCS11_PIN> app.jar <LABEL_SIGN>
jarsigner -verify app.jar
```

For production signing, add a timestamp authority (`-tsa <url>`) so signatures
remain valid after the certificate expires.

### CMS / PKCS#7 (`openssl` + pkcs11 engine)

The workshop writes an OpenSSL config that loads the `pkcs11` engine with
`MODULE_PATH=$MODULE`, then signs and verifies:

```bash
openssl cms -sign -binary -engine pkcs11 -keyform engine \
  -inkey "pkcs11:object=<LABEL_SIGN>;type=private" \
  -signer cert.pem -in data -out data.p7s -outform DER -nodetach
openssl cms -verify -inform DER -in data.p7s -noverify
```

`-noverify` checks the cryptographic signature without requiring the issuing CA
in the local trust store (the demo CA usually isn't). For full chain trust,
import the issuing CA.

## Troubleshooting

### `list` shows no objects

This is the single most common situation. It almost always means the
authenticated identity is **not an authorized signer** of a project that
contains *Ready* signing keys. Checklist:

1. Are you logged in as the **signer** identity (service account), not the
   project owner's API key?
2. Is that identity added as an **authorized signer** on the project (directly
   or via a team)?
3. Does the project have signing keys in status **Ready**?
4. Did you re-login with `--force` after changing authorization? Grants are
   cached; a stale grant won't see newly granted keys.

### `jarsigner` / `openssl` ask for a PIN or fail to load the module

The PKCS#11 token requires a login. Provide the dummy `PKCS11_PIN` (the real
authentication is the cloud grant). The workshop does this automatically.

### `keytool error: load failed`

Usually a missing/incorrect PIN for the SunPKCS11 provider, or a `MODULE` path
that doesn't point at the vendor `.so`. Verify `MODULE` and `PKCS11_PIN`.

### API steps print "Forbidden" or are skipped

`API_TOKEN_FILE` is missing, or the API key lacks access to the queried data.
The signing steps do not require the API; only the inventory/counter steps do.

## Cleanup

Use the menu's **cleanup** option (or remove `WORK`) to delete generated
artifacts and the local session signing log. Optionally log out to revoke the
local grant.
