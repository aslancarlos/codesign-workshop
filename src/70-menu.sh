menu() {
  clear 2>/dev/null
  title "$BRAND"
  say "  $(t 'Identidade' 'Identidad'): ${B}${IDENTITY}${X} (signer · $PROJECT)   |   lang: ${B}${DEMO_LANG}${X}   |   work: ${WORK}"
  echo
  say "  ${B}i${X}) $(t 'Abertura: o problema + arquitetura' 'Apertura: el problema + arquitectura')"
  say "  ${B}1${X}) $(t 'Pré-requisitos e estado' 'Prerrequisitos y estado')"
  say "  ${B}2${X}) $(t 'Login (service account)' 'Login (service account)')"
  say "  ${B}3${X}) $(t 'Separação de funções: owner x signer' 'Separación de funciones: owner x signer')"
  say "  ${B}4${X}) $(t 'Listar certificados e chaves' 'Listar certificados y claves')"
  say "  ${B}5${X}) $(t 'PROVA: a chave fica no HSM' 'PRUEBA: la clave queda en el HSM')"
  say "  ${B}6${X}) $(t 'Baixar certificado + cadeia' 'Descargar certificado + cadena')"
  say "  ${B}7${X}) $(t 'Assinar JAR REAL (jarsigner) + verificar' 'Firmar JAR REAL (jarsigner) + verificar')"
  say "  ${B}8${X}) $(t 'Assinar CMS/PKCS#7 (openssl) + latência' 'Firmar CMS/PKCS#7 (openssl) + latencia')"
  say "  ${B}9${X}) $(t 'Integridade & adulteração' 'Integridad y alteración')"
  say "  ${B}10${X}) $(t 'Governança & não-repúdio (API + auditoria)' 'Gobernanza y no repudio (API + auditoría)')"
  say "  ${B}11${X}) $(t 'Assinaturas por chave & últimos logs' 'Firmas por clave & últimos logs')"
  say "  ${B}12${X}) $(t 'Valor comprovado + compliance' 'Valor comprobado + compliance')"
  echo
  say "  ${B}g${X}) $(t 'Roteiro guiado completo (i→12)' 'Guion guiado completo (i→12)')    ${B}d${X}) $(t 'Diagnóstico' 'Diagnóstico')    ${B}c${X}) $(t 'Limpeza/logout' 'Limpieza/logout')"
  say "  ${B}l${X}) $(t 'Idioma PT/ES' 'Idioma PT/ES')    ${B}q${X}) $(t 'Sair' 'Salir')"
  echo; printf '%s' "${B}$(t 'Escolha:' 'Elija:')${X} "
}

