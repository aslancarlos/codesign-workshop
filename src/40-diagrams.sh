# ------------------------- Diagramas ASCII de fluxo --------------------------
_lock() { printf '   %s\n' "${G}🔒 $(t 'a chave privada NUNCA sai do HSM — só o hash sobe' 'la clave privada NUNCA sale del HSM — sólo el hash sube')${X}"; }

diagram_jar() {
  printf '%s\n' "${B}${C}   $(t 'Como o jarsigner assina via PKCS#11:' 'Cómo firma jarsigner vía PKCS#11:')${X}"
  cat <<EOF
   ┌────────────┐              ┌──────────────┐              ┌────────────┐
   │ jarsigner  │ ─(1)──────>  │ venafipkcs11 │ ─(2)──────>  │  Cloud HSM │
   │ +SunPKCS11 │ <──────(4)─  │  (PKCS#11)   │ <──────(3)─  │ [priv key] │
   └────────────┘              └──────────────┘              └────────────┘
EOF
  _lock
  printf '   (1) %s\n' "$(t 'hash SHA-256 do JAR → módulo' 'hash SHA-256 del JAR → módulo')"
  printf '   (2) %s\n' "$(t 'módulo chama C_Sign(hash) no HSM (grant autentica)' 'módulo llama C_Sign(hash) en el HSM (grant autentica)')"
  printf '   (3) %s\n' "$(t 'HSM devolve a assinatura' 'HSM devuelve la firma')"
  printf '   (4) %s\n' "$(t 'jarsigner grava META-INF/*.SF + *.RSA dentro do JAR' 'jarsigner escribe META-INF/*.SF + *.RSA dentro del JAR')"
}

diagram_cms() {
  printf '%s\n' "${B}${C}   $(t 'Como o openssl assina (CMS/PKCS#7) via engine PKCS#11:' 'Cómo firma openssl (CMS/PKCS#7) vía engine PKCS#11:')${X}"
  cat <<EOF
   ┌────────────┐              ┌──────────────┐              ┌────────────┐
   │  openssl   │ ─(1)──────>  │ venafipkcs11 │ ─(2)──────>  │  Cloud HSM │
   │ cms+engine │ <──────(4)─  │  (PKCS#11)   │ <──────(3)─  │ [priv key] │
   └────────────┘              └──────────────┘              └────────────┘
EOF
  _lock
  printf '   (1) %s\n' "$(t 'hash do conteúdo → módulo' 'hash del contenido → módulo')"
  printf '   (2) %s\n' "$(t 'C_Sign(hash) no HSM' 'C_Sign(hash) en el HSM')"
  printf '   (3) %s\n' "$(t 'HSM devolve a assinatura' 'HSM devuelve la firma')"
  printf '   (4) %s\n' "$(t 'openssl monta o envelope PKCS#7/CMS (cert + assinatura)' 'openssl arma el envelope PKCS#7/CMS (cert + firma)')"
}

diagram_raw() {
  printf '%s\n' "${B}${C}   $(t 'Como o pkcs11config assina (teste de acesso à chave):' 'Cómo firma pkcs11config (prueba de acceso a la clave):')${X}"
  cat <<EOF
   ┌────────────┐              ┌──────────────┐              ┌────────────┐
   │pkcs11config│ ─(1)──────>  │   libhsm /   │ ─(2)──────>  │  Cloud HSM │
   │    sign    │ <──────(4)─  │ venafipkcs11 │ <──────(3)─  │ [priv key] │
   └────────────┘              └──────────────┘              └────────────┘
EOF
  _lock
  printf '   (1) %s\n' "$(t 'SHA-256 do arquivo (local)' 'SHA-256 del archivo (local)')"
  printf '   (2) %s\n' "$(t 'envia só o hash + grant' 'envía sólo el hash + grant')"
  printf '   (3) %s\n' "$(t 'HSM devolve a assinatura RSA' 'HSM devuelve la firma RSA')"
  printf '   (4) %s\n' "$(t 'salva .sig (formato cru, só p/ testar acesso)' 'guarda .sig (formato crudo, sólo para probar acceso)')"
}

diagram_export() {
  printf '%s\n' "${B}${C}   $(t 'Por que a chave privada não pode ser exportada:' '¿Por qué la clave privada no puede exportarse:')${X}"
  cat <<EOF
   ┌────────────┐              ┌──────────────┐    ╳╳╳╳     ┌────────────┐
   │  keytool   │ ─(1)──────>  │ venafipkcs11 │ ──BLOCK──>  │  Cloud HSM │
   │ -importkey │ <──── ✗ (2)  │  (PKCS#11)   │ <────────  │ [priv key] │
   └────────────┘              └──────────────┘            │ WRITE_PROT │
                                                           └────────────┘
EOF
  printf '   %s\n' "${R}🔒 $(t 'token WRITE_PROTECTED · chave CKA_EXTRACTABLE=false' 'token WRITE_PROTECTED · clave CKA_EXTRACTABLE=false')${X}"
  printf '   (1) %s\n' "$(t 'keytool tenta EXTRAIR a chave privada para um .p12' 'keytool intenta EXTRAER la clave privada a un .p12')"
  printf '   (2) %s\n' "${R}$(t 'o HSM RECUSA: a chave é selada e não-exportável por política' 'el HSM RECHAZA: la clave está sellada y es no-exportable por política')${X}"
  printf '   →   %s\n' "$(t 'resultado: 0 chaves exportadas (só cert e chave pública podem sair)' 'resultado: 0 claves exportadas (sólo cert y clave pública pueden salir)')"
}

diagram_arch() {
  printf '%s\n' "${B}${C}   Code Sign Manager (SaaS) - architecture${X}"
  cat <<EOF
   ┌──────────────────────┐   (1) ─────────>   ┌──────────────────────┐
   │  Build / CI / Dev    │                    │   Code Sign Manager  │
   │  jarsigner· openssl  │                    │   (SaaS · HSM FIPS)  │
   │  pkcs11config        │   <───────── (2)   │   [ priv key 🔒 ]    │
   │  (no private key)    │                    │   policy·audit·log   │
   └──────────────────────┘                    └──────────────────────┘
EOF
  _lock
  printf '   (1) %s\n' "$(t 'o cliente envia SÓ o hash do artefato' 'el cliente envía SÓLO el hash del artefacto')"
  printf '   (2) %s\n' "$(t 'o HSM devolve a assinatura (a chave nunca desce)' 'el HSM devuelve la firma (la clave nunca baja)')"
}

