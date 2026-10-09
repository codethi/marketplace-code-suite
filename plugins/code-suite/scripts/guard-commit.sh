#!/usr/bin/env bash
# guard-commit.sh — PreToolUse hook (matcher: Bash).
#
# Reads the hook JSON from stdin. If the Bash command runs `git commit`, scans
# the working tree with `cs-secret-scan --worktree`; if it runs `git push`,
# scans the outgoing range with `cs-secret-scan --range`. When secrets are
# found, explains on stderr and exits 2 (blocks the tool call). Every other
# case exits 0, including scanner errors, so the hook never blocks on its own
# failures.

set -u

script_dir=$(cd "$(dirname "$0")" && pwd)
scanner="$script_dir/../bin/cs-secret-scan"

input=$(cat)

# Prints the string value of the first "<key>" in a JSON document (unescaped).
json_string() {
  printf '%s' "$input" | awk -v want="$1" '
    { buf = buf $0 "\n" }
    END {
      n = length(buf)
      for (i = 1; i <= n; i++) {
        if (substr(buf, i, 1) != "\"") continue
        s = ""
        for (i++; i <= n; i++) {
          c = substr(buf, i, 1)
          if (c == "\\") {
            i++; e = substr(buf, i, 1)
            if (e == "n") s = s "\n"; else if (e == "t") s = s "\t"
            else if (e == "r") s = s "\r"; else if (e == "u") { s = s "?"; i += 4 }
            else s = s e
            continue
          }
          if (c == "\"") break
          s = s c
        }
        j = i + 1
        while (j <= n && substr(buf, j, 1) ~ /[ \t\r\n]/) j++
        if (substr(buf, j, 1) != ":") continue
        if (s != want) { i = j; continue }
        # value must be a string
        j++
        while (j <= n && substr(buf, j, 1) ~ /[ \t\r\n]/) j++
        if (substr(buf, j, 1) != "\"") exit
        v = ""
        for (i = j + 1; i <= n; i++) {
          c = substr(buf, i, 1)
          if (c == "\\") {
            i++; e = substr(buf, i, 1)
            if (e == "n") v = v "\n"; else if (e == "t") v = v "\t"
            else if (e == "r") v = v "\r"; else if (e == "u") { v = v "?"; i += 4 }
            else v = v e
            continue
          }
          if (c == "\"") break
          v = v c
        }
        printf "%s", v
        exit
      }
    }'
}

command=$(json_string command)
[ -n "$command" ] || exit 0

# git [global options] <subcommand>, at the start or after a shell separator.
runs_git() {
  printf '%s\n' "$command" | grep -Eq "(^|[;&|(\`[:space:]])git([[:space:]]+(-[cC][[:space:]]+[^[:space:]]+|--?[A-Za-z-]+(=[^[:space:]]*)?))*[[:space:]]+$1([[:space:]]|[;&|)]|\$)"
}

modes=""
runs_git commit && modes="$modes --worktree"
runs_git push   && modes="$modes --range"
[ -n "$modes" ] || exit 0

cwd=$(json_string cwd)
[ -n "$cwd" ] && cd "$cwd" 2>/dev/null

[ -x "$scanner" ] || exit 0

report=""
blocked=""
for mode in $modes; do
  out=$("$scanner" "$mode" 2>/dev/null)
  if [ $? -eq 1 ]; then
    report="$report$out"$'\n'
    case "$mode" in
      --worktree) blocked="${blocked:+$blocked e }git commit" ;;
      --range)    blocked="${blocked:+$blocked e }git push" ;;
    esac
  fi
done

[ -n "$blocked" ] || exit 0

{
  echo "BLOQUEADO: $blocked — o cs-secret-scan encontrou possíveis segredos nas linhas adicionadas:"
  echo
  printf '%s' "$report" | sed 's/^/  /'
  echo
  echo "Como resolver:"
  echo "  1. Remova o valor do código e leia-o de uma variável de ambiente ou de um cofre de segredos."
  echo "  2. Se o segredo já foi commitado (caso do push), reescreva o commit para tirá-lo do histórico"
  echo "     e revogue/rotacione a credencial, pois ela pode já ter vazado."
  echo "  3. Se for falso positivo, acrescente o comentário 'secret-scan:allow' na própria linha"
  echo "     (ex.: // secret-scan:allow ou # secret-scan:allow) e tente de novo."
} >&2
exit 2
