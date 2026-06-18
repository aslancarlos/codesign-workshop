require_bin
choose_lang
while true; do
  menu
  if ! read -r opt; then say ""; exit 0; fi   # EOF (stdin fechado) encerra
  case "$opt" in
    i|I) step_intro ;;
    1) step_status ;;  2) step_login ;;   3) step_sod ;;     4) step_list ;;
    5) step_proof ;;   6) step_getcert ;; 7) step_sign_jar ;; 8) step_sign_cms ;;
    9) step_tamper ;;  10) step_governance ;; 11) step_signings ;; 12) step_value ;;
    g|G) step_guided ;;
    d|D) step_diag ;;  c|C) step_cleanup ;;
    l|L) DEMO_LANG=$([ "$DEMO_LANG" = "es" ] && echo pt || echo es) ;;
    q|Q) say "$(t 'Até mais.' 'Hasta luego.')"; exit 0 ;;
    *) err "$(t 'Opção inválida.' 'Opción inválida.')"; sleep 1 ;;
  esac
done
