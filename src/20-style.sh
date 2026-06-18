if [ -t 1 ]; then
  B=$'\e[1m'; G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; R=$'\e[31m'; M=$'\e[35m'; X=$'\e[0m'
else B=""; G=""; Y=""; C=""; R=""; M=""; X=""; fi

t() { if [ "$DEMO_LANG" = "es" ]; then printf '%s' "$2"; else printf '%s' "$1"; fi; }
say()   { printf '%s\n' "$*"; }
title() { clear 2>/dev/null; printf '%s\n%s\n%s\n' "${B}${C}══════════════════════════════════════════════════════════════════════${X}" "${B}${C} $* ${X}" "${B}${C}══════════════════════════════════════════════════════════════════════${X}"; }
note()  { printf '%s\n' "${Y}» $*${X}"; }
ok()    { printf '%s\n' "${G}[OK] $*${X}"; }
err()   { printf '%s\n' "${R}[ERRO] $*${X}"; }
fail()  { printf '%s\n' "${R}${B}[$(t 'FALHOU' 'FALLÓ')]${X} ${R}$*${X}"; }
show()  { printf '%s\n' "${B}\$ $*${X}"; }
run()   { printf '%s\n' "${B}\$ $*${X}"; eval "$*"; }
pause() { printf '\n%s' "${B}$(t 'Pressione ENTER para continuar...' 'Presione ENTER para continuar...')${X}"; read -r _; }

