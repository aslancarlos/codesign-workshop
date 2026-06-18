require_bin() {
  command -v pkcs11config >/dev/null 2>&1 || { err "$(t 'pkcs11config ausente. Rode na máquina devsecops-tools.' 'pkcs11config ausente. Ejecute en la máquina devsecops-tools.')"; exit 1; }
}
choose_lang() {
  [ "$DEMO_LANG" = "pt" ] || [ "$DEMO_LANG" = "es" ] && return
  clear 2>/dev/null
  printf '%s\n\n  %s1%s) Português\n  %s2%s) Español\n\n' "${B}${C} Idioma / Idioma ${X}" "$B" "$X" "$B" "$X"
  printf '%s' "${B}Escolha / Elija [1]: ${X}"; read -r l
  case "$l" in 2|es|ES) DEMO_LANG="es" ;; *) DEMO_LANG="pt" ;; esac
}

# =============================================================================
# i) ABERTURA — problema de negócio + arquitetura
# =============================================================================
