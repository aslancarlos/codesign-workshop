step_intro() {
  title "$(t 'ABERTURA — Por que isto importa' 'APERTURA — Por qué esto importa')"
  note "$(t 'A assinatura de código é a base da confiança no software. Se a CHAVE PRIVADA' \
          'La firma de código es la base de la confianza del software. Si la CLAVE PRIVADA')"
  note "$(t 'de assinatura vaza, o atacante assina malware como se fosse você.' \
          'de firma se filtra, el atacante firma malware como si fuera usted.')"
  echo
  say "  ${R}$(t 'Casos reais de chaves de assinatura roubadas/abusadas:' 'Casos reales de claves de firma robadas/abusadas:')${X}"
  say "   • SolarWinds (2020)   • NVIDIA / LAPSUS\$ (2022)   • Stuxnet (2010)   • 3CX (2023)"
  echo
  note "$(t 'A resposta: chaves em HSM, centralizadas, com política e auditoria.' \
          'La respuesta: claves en HSM, centralizadas, con política y auditoría.')"
  echo
  say "  ${B}${C}$(t 'ARQUITETURA — a chave NUNCA sai do HSM' 'ARQUITECTURA — la clave NUNCA sale del HSM')${X}"
  echo; diagram_arch
  echo; note "$(t 'Neste workshop vamos PROVAR cada uma dessas afirmações, ao vivo.' 'En este workshop vamos a DEMOSTRAR cada una de esas afirmaciones, en vivo.')"
  pause
}

# =============================================================================
# 1) Pré-requisitos
# =============================================================================
step_status() {
  title "$(t '1) Pré-requisitos e estado' '1) Prerrequisitos y estado')"
  note "$(t 'Versão do cliente e validade do login/grant.' 'Versión del cliente y validez del login/grant.')"
  echo; run "pkcs11config version"; echo; run "pkcs11config checklogin"
  pause
}

# =============================================================================
# 2) Login service account
# =============================================================================
step_login() {
  title "$(t '2) Login como Service Account' '2) Login como Service Account')"
  note "$(t 'Identidade de máquina (Client ID + chave privada) — ideal para CI/CD.' \
          'Identidad de máquina (Client ID + clave privada) — ideal para CI/CD.')"
  say "  Client ID : ${B}${CLIENT_ID}${X}"
  [ -n "$CLIENT_ID" ] || { err "$(t 'Defina CLIENT_ID (UUID da service account).' 'Defina CLIENT_ID (UUID de la service account).')"; pause; return; }
  [ -r "$KEYFILE" ] || { err "$(t "Chave não encontrada: $KEYFILE" "Clave no encontrada: $KEYFILE")"; pause; return; }
  echo; run "pkcs11config login --clientid='$CLIENT_ID' --keyfile='$KEYFILE' --force"
  echo; run "pkcs11config checklogin"
  pause
}

# =============================================================================
# 3) Separação de funções — owner x authorized signer
# =============================================================================
step_sod() {
  title "$(t '3) Separação de funções: owner x authorized signer' '3) Separación de funciones: owner x authorized signer')"
  note "$(t 'Governança real: ser DONO do projeto NÃO dá acesso às chaves.' \
          'Gobernanza real: ser DUEÑO del proyecto NO da acceso a las claves.')"
  note "$(t 'Só quem é AUTHORIZED SIGNER assina. Vamos provar com 2 identidades.' \
          'Sólo quien es AUTHORIZED SIGNER firma. Vamos a probarlo con 2 identidades.')"
  if [ ! -r "$API_TOKEN_FILE" ]; then
    note "$(t '(api-key do owner indisponível; pulando a comparação ao vivo)' '(api-key del owner no disponible; omitiendo la comparación)')"; pause; return
  fi
  echo
  say "  ${B}A)${X} $(t 'Identidade OWNER (api-key do usuário dono do projeto):' 'Identidad OWNER (api-key del usuario dueño del proyecto):')"
  _tok=$(get_tok); _mask="${_tok:0:4}…${_tok: -4}"
  show "pkcs11config login --token='${_mask}' --force ; pkcs11config list"
  pkcs11config login --token="$_tok" --force >/dev/null 2>&1; pkcs11config list 2>&1 | tail -1
  unset _tok _mask
  printf '   %s\n' "${R}$(t '↳ owner NÃO vê nenhuma chave.' '↳ el owner NO ve ninguna clave.')${X}"
  echo
  say "  ${B}B)${X} $(t 'Identidade SIGNER (service account):' 'Identidad SIGNER (service account):')"
  run "pkcs11config login --clientid='$CLIENT_ID' --keyfile='$KEYFILE' --force >/dev/null 2>&1; pkcs11config list 2>&1 | tail -1"
  printf '   %s\n' "${G}$(t '↳ signer VÊ as chaves do projeto.' '↳ el signer VE las claves del proyecto.')${X}"
  echo; ok "$(t 'Mesma plataforma, autorização granular por projeto. Voltamos para a SA.' \
              'Misma plataforma, autorización granular por proyecto. Volvemos a la SA.')"
  pause
}

# =============================================================================
# 4) Listar chaves no cliente
# =============================================================================
step_list() {
  title "$(t '4) Listar certificados e chaves' '4) Listar certificados y claves')"
  note "$(t "O cliente recebe REFERÊNCIAS (não as chaves). '--force' recarrega do servidor." \
          "El cliente recibe REFERENCIAS (no las claves). '--force' recarga del servidor.")"
  echo; run "pkcs11config list --env=all --type=all --force --table"
  pause
}

# =============================================================================
# 5) Prova: a chave NÃO sai do HSM
# =============================================================================
step_proof() {
  title "$(t '5) Prova: a chave privada NUNCA sai do HSM' '5) Prueba: la clave privada NUNCA sale del HSM')"
  ensure_configs
  note "$(t 'O token PKCS#11 é WRITE_PROTECTED e as chaves são NÃO-EXTRAÍVEIS.' \
          'El token PKCS#11 es WRITE_PROTECTED y las claves son NO-EXTRAÍBLES.')"
  note "$(t 'Vamos TENTAR exportar a chave privada para um arquivo .p12 — deve FALHAR.' \
          'Vamos a INTENTAR exportar la clave privada a un .p12 — debe FALLAR.')"
  echo; diagram_export; echo
  show "keytool -storetype PKCS11 ... -importkeystore -destkeystore chave.p12  # $(t 'tentativa de exportação' 'intento de exportación')"
  note "$(t 'Aguarde até 10s (o HSM nega a exportação)...' 'Espere hasta 10s (el HSM niega la exportación)...')"
  out=$(timeout 10 keytool -keystore NONE -storetype PKCS11 -providerClass sun.security.pkcs11.SunPKCS11 \
        -providerArg "$WORK/p11.cfg" -storepass "$PKCS11_PIN" -importkeystore \
        -srckeystore NONE -srcstoretype PKCS11 -srcstorepass "$PKCS11_PIN" \
        -destkeystore "$WORK/chave.p12" -deststoretype PKCS12 -deststorepass changeit < /dev/null 2>&1); rc=$?
  printf '  %s\n' "${R}$(echo "$out" | grep -iE 'not imported|failed|cancelled' | head -3)${X}"
  [ $rc -eq 124 ] && note "$(t '(tempo esgotado em 10s — exportação não concluída)' '(tiempo agotado en 10s — exportación no completada)')"
  echo
  if [ -s "$WORK/chave.p12" ] && keytool -list -keystore "$WORK/chave.p12" -storepass changeit < /dev/null 2>/dev/null | grep -qi PrivateKey; then
    err "$(t 'Conseguiu exportar — NÃO esperado.' 'Logró exportar — NO esperado.')"
  else
    fail "$(t 'Exportação da chave privada REJEITADA pelo HSM (0 chaves exportadas).' \
            'Exportación de la clave privada RECHAZADA por el HSM (0 claves exportadas).')"
    note "$(t '↳ Resultado ESPERADO: a chave privada é selada no HSM. Só saem cert e chave pública.' \
            '↳ Resultado ESPERADO: la clave privada está sellada en el HSM. Sólo salen cert y clave pública.')"
  fi
  pause
}

# =============================================================================
# 6) Baixar certificado
# =============================================================================
step_getcert() {
  title "$(t "6) Baixar certificado + cadeia ($LABEL_CERT)" "6) Descargar certificado + cadena ($LABEL_CERT)")"
  ensure_work
  note "$(t 'Baixa só a parte PÚBLICA. A chave privada continua no HSM.' \
          'Descarga sólo la parte PÚBLICA. La clave privada permanece en el HSM.')"
  echo; run "pkcs11config getcertificate --label='$LABEL_CERT' --filename='$WORK/cert.pem' --chainfile='$WORK/chain.pem' --force"
  [ -s "$WORK/cert.pem" ] && { echo; run "openssl x509 -in '$WORK/cert.pem' -noout -subject -issuer -dates"; }
  pause
}

# =============================================================================
# 7) Assinar JAR real (jarsigner / SunPKCS11)
# =============================================================================
step_sign_jar() {
  title "$(t '7) Assinar um JAR REAL (jarsigner + HSM)' '7) Firmar un JAR REAL (jarsigner + HSM)')"
  command -v jarsigner >/dev/null 2>&1 || { err "jarsigner $(t 'ausente' 'ausente')"; pause; return; }
  ensure_configs
  note "$(t 'Caso de uso clássico: assinar um artefato Java. A chave fica no HSM;' \
          'Caso de uso clásico: firmar un artefacto Java. La clave queda en el HSM;')"
  note "$(t 'o jarsigner usa o módulo PKCS#11 da Venafi como keystore.' \
          'jarsigner usa el módulo PKCS#11 de Venafi como keystore.')"
  echo; diagram_jar; echo
  run "printf 'build %s\n' \"\$(date -u)\" > '$WORK/app.txt'; (cd '$WORK' && jar cf app.jar app.txt)"
  _jarhash=$(sha256sum "$WORK/app.jar" 2>/dev/null | awk '{print $1}')   # hash do JAR ORIGINAL (pré-assinatura)
  echo; note "$(t 'Assinando o JAR com a chave do HSM (' 'Firmando el JAR con la clave del HSM (')$LABEL_SIGN):"
  show "jarsigner -storetype PKCS11 -providerClass sun.security.pkcs11.SunPKCS11 -providerArg p11.cfg $WORK/app.jar $LABEL_SIGN"
  jout=$(jarsigner -keystore NONE -storetype PKCS11 -providerClass sun.security.pkcs11.SunPKCS11 \
    -providerArg "$WORK/p11.cfg" -storepass "$PKCS11_PIN" "$WORK/app.jar" "$LABEL_SIGN" 2>&1)
  echo "$jout" | grep -qi "jar signed" && { ok "jar signed — $(t 'assinado pela chave no HSM.' 'firmado por la clave en el HSM.')"; log_signing "$LABEL_SIGN" "jarsigner" "$WORK/app.jar" "RSA-2048" "OK" "$_jarhash"; }
  echo "$jout" | grep -qiE "PKIX|chain is invalid" && note "$(t '(A CA de demonstração ZTPKI não está no trust store local do SO — é só ambiente de lab, não falha do produto.)' \
                                                                 '(La CA demo ZTPKI no está en el trust store local del SO — es sólo lab, no falla del producto.)')"
  echo "$jout" | grep -qiE "expire within six months" && note "$(t '(Cert de demo expira em <6 meses; em produção use -tsa para carimbo de tempo.)' \
                                                                    '(El cert demo expira en <6 meses; en producción use -tsa para sello de tiempo.)')"
  echo; note "$(t 'Verificando a assinatura do JAR (ferramenta NATIVA do Java):' \
              'Verificando la firma del JAR (herramienta NATIVA de Java):')"
  show "jarsigner -verify -certs $WORK/app.jar"
  if jarsigner -verify "$WORK/app.jar" 2>/dev/null | grep -qi "jar verified"; then
    ok "$(t 'jar verified — assinatura válida, gerada pelo HSM.' 'jar verified — firma válida, generada por el HSM.')"
  else
    err "$(t 'Verificação do JAR falhou.' 'La verificación del JAR falló.')"
  fi
  note "$(t '(Em produção: adicionar carimbo de tempo -tsa para validade pós-expiração.)' \
          '(En producción: agregar sello de tiempo -tsa para validez tras expiración.)')"
  pause
}

# =============================================================================
# 8) Assinar CMS/PKCS#7 (openssl engine) + latência
# =============================================================================
step_sign_cms() {
  title "$(t '8) Assinar CMS/PKCS#7 (openssl + engine PKCS#11)' '8) Firmar CMS/PKCS#7 (openssl + engine PKCS#11)')"
  ensure_configs
  [ -s "$WORK/cert.pem" ] || pkcs11config getcertificate --label="$LABEL_SIGN" --filename="$WORK/cert.pem" --force >/dev/null 2>&1
  pkcs11config getcertificate --label="$LABEL_SIGN" --filename="$WORK/sign.pem" --force >/dev/null 2>&1
  note "$(t 'Assinatura padrão da indústria (CMS/PKCS#7), via OpenSSL, chave no HSM.' \
          'Firma estándar de la industria (CMS/PKCS#7), vía OpenSSL, clave en el HSM.')"
  echo; diagram_cms; echo
  run "printf 'conteudo a assinar %s\n' \"\$(date -u)\" > '$WORK/data.txt'"
  echo; note "$(t 'Assinando (medindo a latência do round-trip ao HSM):' \
              'Firmando (midiendo la latencia del round-trip al HSM):')"
  show "OPENSSL_CONF=ossl.cnf openssl cms -sign -engine pkcs11 -keyform engine -inkey 'pkcs11:object=$LABEL_SIGN;type=private' -signer sign.pem ..."
  t0=$(date +%s%3N)
  OPENSSL_CONF="$WORK/ossl.cnf" openssl cms -sign -binary -engine pkcs11 -keyform engine \
    -inkey "pkcs11:object=$LABEL_SIGN;type=private;pin-value=$PKCS11_PIN" \
    -signer "$WORK/sign.pem" -in "$WORK/data.txt" -out "$WORK/data.p7s" -outform DER -nodetach >/dev/null 2>&1
  t1=$(date +%s%3N)
  if [ -s "$WORK/data.p7s" ]; then
    ok "$(t 'Assinatura CMS gerada:' 'Firma CMS generada:') $(wc -c < "$WORK/data.p7s") bytes  ${B}(${M}$((t1-t0)) ms${X}${B})${X}"
    log_signing "$LABEL_SIGN" "openssl-cms" "$WORK/data.txt" "RSA-2048" "OK"
  else
    err "$(t 'Falha ao assinar CMS.' 'Falla al firmar CMS.')"; pause; return
  fi
  echo; note "$(t 'Verificando a assinatura CMS:' 'Verificando la firma CMS:')"
  show "openssl cms -verify -inform DER -in data.p7s -noverify"
  vout=$(OPENSSL_CONF="$WORK/ossl.cnf" openssl cms -verify -inform DER -in "$WORK/data.p7s" -noverify 2>&1 >"$WORK/cms.out")
  if echo "$vout" | grep -qi "Verification successful"; then
    ok "$(t 'CMS Verification successful — conteúdo recuperado:' 'CMS Verification successful — contenido recuperado:') $(cat "$WORK/cms.out" 2>/dev/null)"
    note "$(t "(-noverify checa a assinatura; a confiança de cadeia usa a CA ZTPKI da Venafi.)" \
            "(-noverify revisa la firma; la confianza de cadena usa la CA ZTPKI de Venafi.)")"
  else
    err "$(t 'Verificação CMS falhou.' 'La verificación CMS falló.')"
  fi
  pause
}

# =============================================================================
# 9) Integridade & adulteração (raw sign + teste negativo [FALHOU])
# =============================================================================
step_tamper() {
  title "$(t '9) Integridade & adulteração' '9) Integridad y alteración')"
  ensure_work
  note "$(t 'Assinamos um arquivo, depois o adulteramos e verificamos a MESMA assinatura.' \
          'Firmamos un archivo, luego lo alteramos y verificamos la MISMA firma.')"
  echo; diagram_raw; echo
  pkcs11config getcertificate --label="$LABEL_SIGN" --filename="$WORK/sign.pem" --force >/dev/null 2>&1
  openssl x509 -in "$WORK/sign.pem" -pubkey -noout > "$WORK/pub.pem" 2>/dev/null
  run "printf 'artefato original %s\n' \"\$(date -u)\" > '$WORK/a.bin'"
  run "pkcs11config sign --label='$LABEL_SIGN' --filename='$WORK/a.bin' --output='$WORK/a.sig' --force >/dev/null 2>&1; echo assinado"
  log_signing "$LABEL_SIGN" "pkcs11config" "$WORK/a.bin" "RSA-2048" "OK"
  echo
  printf '%s\n' "${B}${G}── $(t 'TESTE POSITIVO' 'PRUEBA POSITIVA') ──────────────────────────────${X}"
  show "openssl dgst -sha256 -verify pub.pem -signature a.sig a.bin"
  if openssl dgst -sha256 -verify "$WORK/pub.pem" -signature "$WORK/a.sig" "$WORK/a.bin"; then
    ok "$(t 'Assinatura VÁLIDA para o arquivo original.' 'Firma VÁLIDA para el archivo original.')"
  else err "$(t 'Falhou no original.' 'Falló en el original.')"; fi
  echo
  printf '%s\n' "${B}${R}── $(t 'TESTE NEGATIVO' 'PRUEBA NEGATIVA') ──────────────────────────────${X}"
  cp "$WORK/a.bin" "$WORK/a_tampered.bin"; printf '%s\n' "$(t '>>> linha adulterada <<<' '>>> línea alterada <<<')" >> "$WORK/a_tampered.bin"
  oh=$(sha256sum "$WORK/a.bin" | awk '{print $1}'); th=$(sha256sum "$WORK/a_tampered.bin" | awk '{print $1}')
  printf '    %-11s %s\n' "$(t 'original' 'original')"  "${G}${oh}${X}"
  printf '    %-11s %s\n' "$(t 'adulterado' 'alterado')" "${R}${th}${X}"
  echo; note "$(t 'Saída do OpenSSL no arquivo adulterado:' 'Salida de OpenSSL en el archivo alterado:')"
  nout=$(openssl dgst -sha256 -verify "$WORK/pub.pem" -signature "$WORK/a.sig" "$WORK/a_tampered.bin" 2>&1); nrc=$?
  printf '  %s\n  %s\n' "${R}${nout}${X}" "$(t 'exit code:' 'exit code:') ${R}${nrc}${X}"
  echo
  if [ $nrc -ne 0 ]; then
    fail "$(t 'Verificação REJEITADA no arquivo adulterado.' 'Verificación RECHAZADA en el archivo alterado.')"
    note "$(t '↳ ESPERADO: a assinatura não bate com o conteúdo alterado — integridade comprovada.' \
            '↳ ESPERADO: la firma no coincide con el contenido alterado — integridad comprobada.')"
  else err "$(t 'ATENÇÃO: verificou arquivo adulterado!' '¡ATENCIÓN: verificó archivo alterado!')"; fi
  pause
}

# =============================================================================
# 10) Governança & não-repúdio (inventário via API + auditoria)
# =============================================================================
step_governance() {
  title "$(t '10) Governança & não-repúdio' '10) Gobernanza y no repudio')"
  note "$(t 'Tudo é centralizado: inventário de chaves, status e quem pode assinar.' \
          'Todo es centralizado: inventario de claves, estado y quién puede firmar.')"
  if [ ! -r "$API_TOKEN_FILE" ]; then note "$(t '(API indisponível neste host)' '(API no disponible en este host)')"; pause; return; fi
  echo; note "$(t 'Inventário central de signing keys (via API GraphQL):' 'Inventario central de signing keys (vía API GraphQL):')"
  show "GET $API_BASE/graphql  { codeSignSigningKeys { name status project } }"
  gql "{ codeSignSigningKeys { nodes { name status project { name } } } }" \
    | python3 -c "import json,sys
d=json.load(sys.stdin).get('data',{}).get('codeSignSigningKeys',{}).get('nodes',[])
print('   %-26s %-10s %s'%('KEY','STATUS','PROJECT'))
for k in d: print('   %-26s %-10s %s'%(k['name'],k['status'],(k.get('project') or {}).get('name','')))" 2>/dev/null
  echo; note "$(t 'Quem pode assinar no projeto' 'Quién puede firmar en el proyecto') $PROJECT:"
  gql "{ codeSignProjects { nodes { name authorizedSigners { __typename ... on ServiceAccount { id } ... on Team { name } } } } }" \
    | python3 -c "import json,sys
for p in json.load(sys.stdin).get('data',{}).get('codeSignProjects',{}).get('nodes',[]):
  if p['name']=='$PROJECT':
    for s in p['authorizedSigners']:
      print('   - %s %s'%(s['__typename'], s.get('name') or s.get('id','')))" 2>/dev/null
  echo
  ok "$(t 'Não-repúdio: cada operação de assinatura é registrada na trilha de auditoria.' \
          'No repudio: cada operación de firma queda registrada en la auditoría.')"
  note "$(t 'Auditoria completa no console: Code Sign Manager → Projects → ' \
          'Auditoría completa en la consola: Code Sign Manager → Projects → ')$PROJECT → Log / Activity"
  say "   https://ui.venafi.cloud${TENANT:+  (tenant: ${B}${TENANT}${X})}"
  pause
}

# =============================================================================
# 11) Assinaturas por chave + últimos logs
# =============================================================================
step_signings() {
  title "$(t '11) Assinaturas por chave & últimos logs' '11) Firmas por clave & últimos logs')"
  if [ ! -r "$API_TOKEN_FILE" ]; then note "$(t '(API indisponível neste host)' '(API no disponible en este host)')"; pause; return; fi
  note "$(t 'Cada operação de assinatura é contabilizada centralmente pela plataforma.' \
          'Cada operación de firma es contabilizada centralmente por la plataforma.')"
  echo; note "$(t 'Total de assinaturas por chave no projeto' 'Total de firmas por clave en el proyecto') $PROJECT (statistics.totalSignings):"
  show "GraphQL { codeSignSigningKeys { name statistics { totalSignings } } }"
  gql "{ codeSignSigningKeys { nodes { name status project { name } statistics { totalSignings } } } }" \
    | python3 -c "
import json,sys
d=json.load(sys.stdin).get('data',{}).get('codeSignSigningKeys',{}).get('nodes',[])
rows=[k for k in d if (k.get('project') or {}).get('name')=='$PROJECT']
print('   %-24s %-8s %s'%('$(t 'CHAVE' 'CLAVE')','STATUS','$(t 'ASSINATURAS' 'FIRMAS')'))
print('   '+'-'*46)
tot=0
for k in rows:
    n=int(k['statistics']['totalSignings']); tot+=n
    print('   %-24s %-8s %d'%(k['name'],k['status'],n))
print('   '+'-'*46)
print('   %-24s %-8s %d'%('TOTAL','',tot))
" 2>/dev/null
  echo; note "$(t 'Últimos 5 registros de assinatura desta sessão (detalhe):' \
              'Últimos 5 registros de firma de esta sesión (detalle):')"
  if [ -s "$WORK/signing_audit.log" ]; then
    n=0
    tail -5 "$WORK/signing_audit.log" | while IFS='|' read -r ts ident key tool art algo res h; do
      n=$((n+1))
      printf '   %s[%d]%s %s   %s%s%s  →  %s%s%s (%s)\n' "$B" "$n" "$X" "$ts" "$C" "$ident" "$X" "$B" "$key" "$X" "$algo"
      printf '       %-11s %-13s %-10s %-11s %-10s %s%s%s\n' \
        "$(t 'ferramenta:' 'herramienta:')" "$tool" "$(t 'artefato:' 'artefacto:')" "$art" "$(t 'resultado:' 'resultado:')" "$G" "$res" "$X"
      printf '       sha256:     %s\n' "$h"
    done
  else
    note "$(t '(nenhuma assinatura registrada nesta sessão — rode os passos 7, 8 e 9)' \
            '(ninguna firma registrada en esta sesión — ejecute los pasos 7, 8 y 9)')"
  fi
  echo
  note "$(t '↳ Detalhe acima = log local que o workshop grava a cada assinatura.' \
          '↳ Detalle arriba = log local que el workshop registra en cada firma.')"
  note "$(t 'Auditoria COMPLETA da plataforma (todas as identidades/datas) no console:' \
          'Auditoría COMPLETA de la plataforma (todas las identidades/fechas) en la consola:')"
  say  "   https://ui.venafi.cloud  →  Code Sign Manager → Projects → $PROJECT → Log"
  note "$(t '(o endpoint de activity-log via API retorna 403 para esta api-key — acesso restrito)' \
          '(el endpoint de activity-log vía API devuelve 403 para esta api-key — acceso restringido)')"
  pause
}

# =============================================================================
# 12) Valor comprovado + compliance (fechamento)
# =============================================================================
step_value() {
  title "$(t '12) Valor comprovado' '12) Valor comprobado')"
  say "  ${G}✔${X} $(t 'A chave privada NUNCA saiu do HSM (exportação rejeitada).' 'La clave privada NUNCA salió del HSM (exportación rechazada).')"
  say "  ${G}✔${X} $(t 'Assinatura REAL e verificável: JAR (jarsigner) e CMS (openssl).' 'Firma REAL y verificable: JAR (jarsigner) y CMS (openssl).')"
  say "  ${G}✔${X} $(t 'Integridade garantida: adulteração é detectada.' 'Integridad garantizada: la alteración se detecta.')"
  say "  ${G}✔${X} $(t 'Separação de funções: owner ≠ signer; autorização por projeto.' 'Separación de funciones: owner ≠ signer; autorización por proyecto.')"
  say "  ${G}✔${X} $(t 'Governança central: inventário, política e auditoria/não-repúdio.' 'Gobernanza central: inventario, política y auditoría/no repudio.')"
  say "  ${G}✔${X} $(t 'Integra no toolchain (PKCS#11): CI/CD, Java, OpenSSL, GPG, Authenticode.' 'Se integra al toolchain (PKCS#11): CI/CD, Java, OpenSSL, GPG, Authenticode.')"
  echo
  say "  ${B}${C}$(t 'Aderência a frameworks:' 'Adherencia a frameworks:')${X}"
  say "   • FIPS 140-2/3 (HSM)   • US Exec. Order 14028   • SLSA / $(t 'cadeia de suprimentos' 'cadena de suministro')"
  say "   • EU Cyber Resilience Act   • PCI-DSS / SOC 2 ($(t 'controles de chave' 'controles de clave'))"
  echo
  note "$(t 'Pergunta de fechamento: hoje, onde estão as suas chaves de assinatura e' \
          'Pregunta de cierre: hoy, ¿dónde están sus claves de firma y')"
  note "$(t 'quem consegue usá-las sem deixar rastro?' 'quién puede usarlas sin dejar rastro?')"
  pause
}

# =============================================================================
# Diagnóstico / Limpeza
# =============================================================================
step_diag() {
  title "$(t 'Diagnóstico' 'Diagnóstico')"
  run "pkcs11config checklogin"; echo; run "pkcs11config health 2>&1 | sed -n '1,30p'"
  echo; note "$(t "Se 'list' vazio: logado como signer? SA autorizada? Keys 'Ready'? Refez login --force?" \
              "Si 'list' vacío: ¿logado como signer? ¿SA autorizada? ¿Keys 'Ready'? ¿Rehízo login --force?")"
  pause
}
step_cleanup() {
  title "$(t 'Limpeza / logout' 'Limpieza / logout')"
  printf '%s' "$(t "Apagar '$WORK'? [s/N] " "¿Borrar '$WORK'? [s/N] ")"; read -r a
  if [ "$a" = s ] || [ "$a" = S ]; then rm -rf "$WORK"; ok "$(t 'Removido.' 'Eliminado.')"; else note "$(t 'Mantido.' 'Conservado.')"; fi
  printf '%s' "$(t 'Logout da service account? [s/N] ' '¿Logout de la service account? [s/N] ')"; read -r b
  if [ "$b" = s ] || [ "$b" = S ]; then pkcs11config logout; ok "$(t 'Logout feito.' 'Logout hecho.')"; else note "$(t 'Login mantido.' 'Sesión conservada.')"; fi
  pause
}

# =============================================================================
# Roteiro guiado completo
# =============================================================================
step_guided() {
  step_intro; step_status; step_login; step_sod; step_list; step_proof
  step_getcert; step_sign_jar; step_sign_cms; step_tamper; step_governance; step_signings; step_value
}

# =============================================================================
# MENU
# =============================================================================
