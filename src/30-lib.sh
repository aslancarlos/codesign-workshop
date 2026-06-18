get_tok() { tr -d ' \t\r\n' < "$API_TOKEN_FILE" 2>/dev/null; }
gql()     { curl -s -X POST "$API_BASE/graphql" -H "tppl-api-key: $(get_tok)" -H "Content-Type: application/json" -d "{\"query\":\"$1\"}"; }

ensure_work()    { mkdir -p "$WORK"; }
ensure_configs() {
  ensure_work
  printf 'name = Venafi\nlibrary = %s\n' "$MODULE" > "$WORK/p11.cfg"
  cat > "$WORK/ossl.cnf" <<EOF
openssl_conf = openssl_init
[openssl_init]
engines = engine_section
[engine_section]
pkcs11 = pkcs11_section
[pkcs11_section]
engine_id = pkcs11
dynamic_path = $ENGINE_SO
MODULE_PATH = $MODULE
init = 0
EOF
}
sa_login() { pkcs11config login --clientid="$CLIENT_ID" --keyfile="$KEYFILE" --force >/dev/null 2>&1; }

# Registra cada assinatura feita pelo workshop (log local da sessão).
# uso: log_signing <chave> <ferramenta> <artefato> <algo> <resultado>
log_signing() {
  ensure_work
  local key="$1" tool="$2" path="$3" algo="$4" res="$5" pre="$6" art h
  art=$(basename "$path" 2>/dev/null)
  if [ -n "$pre" ]; then h="$pre"; else h=$(sha256sum "$path" 2>/dev/null | awk '{print $1}'); fi
  [ -n "$h" ] || h="-"
  printf '%s|%s|%s|%s|%s|%s|%s|%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$IDENTITY" "$key" "$tool" "$art" "$algo" "$res" "$h" >> "$WORK/signing_audit.log"
}

