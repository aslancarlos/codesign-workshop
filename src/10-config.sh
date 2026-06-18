# -------------------------- CONFIGURÁVEL / CONFIGURABLE ----------------------
CLIENT_ID="${CLIENT_ID:-}"                                       # service account UUID (required for login)
KEYFILE="${KEYFILE:-$HOME/.codesign/service_account.key}"        # service account private key (PEM)
API_TOKEN_FILE="${API_TOKEN_FILE:-$HOME/.codesign/api_token}"    # API key file (optional; enables API-backed steps)
LABEL_SIGN="${LABEL_SIGN:-signing-key}"                          # signing key label (see 'pkcs11config list')
LABEL_CERT="${LABEL_CERT:-$LABEL_SIGN}"                          # certificate label to download
PROJECT="${PROJECT:-my-project}"                                 # Code Sign project name
IDENTITY="${IDENTITY:-signer}"                                   # display name for the signing identity
TENANT="${TENANT:-}"                                             # tenant / url prefix (optional; console hints)
API_BASE="${API_BASE:-https://api.venafi.cloud}"                 # API region base (US default; EU/AU/UK/SG/CA differ)
BRAND="${BRAND:-Machine Identity - Code Signing Workshop}"       # banner / title text
WORK="${WORK:-/tmp/codesign_demo}"
MODULE="${MODULE:-/opt/venafi/codesign/lib/venafipkcs11.so}"
ENGINE_SO="${ENGINE_SO:-/usr/lib/x86_64-linux-gnu/engines-3/pkcs11.so}"
PKCS11_PIN="${PKCS11_PIN:-1234}"   # PIN "dummy": a auth real é o grant na nuvem
DEMO_LANG="${DEMO_LANG:-}"         # pt | es ; vazio = pergunta no início
# -----------------------------------------------------------------------------

