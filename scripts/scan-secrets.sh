#!/bin/bash
# de-omarchy secret scan — run before EVERY commit/push (see SECURITY.md).
# Uses gitleaks when available, plus manual greps for what scanners miss.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")/.."

HITS=0
fail() { echo "  [SECRET?] $*"; HITS=$((HITS+1)); }

echo "== gitleaks =="
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks detect --source . --no-banner -v || echo "  gitleaks clean"
else
  echo "  gitleaks not installed — install it: pacman -S gitleaks"
fi

echo "== manual greps =="
PATTERNS=(
  'BEGIN OPENSSH PRIVATE KEY' 'BEGIN RSA PRIVATE KEY' 'BEGIN EC PRIVATE KEY'
  'BEGIN PGP PRIVATE KEY'
  'ANTHROPIC_AUTH_TOKEN=' 'ANTHROPIC_API_KEY='
  '(password|passwd|psk)\s*=\s*["'"'"'][^"'"'"']{4,}'
  'Bearer [A-Za-z0-9_\-\.]{10,}'
  'Authorization:'
  'AKIA[0-9A-Z]{16}'
  'ghp_[A-Za-z0-9]{30,}' 'github_pat_'
  'sk-[A-Za-z0-9]{20,}'
  '/home/[a-z0-9_]+'          # hardcoded real usernames must not appear
)
for p in "${PATTERNS[@]}"; do
  # shellcheck disable=SC2086
  while IFS=: read -r file line _; do
    case $file in
      .git/*|audit/system-fingerprint.md) continue ;;   # fingerprint is scrubbed by design
    esac
    fail "$file:$line matches /$p/"
  done < <(grep -rInE "$p" . --exclude-dir=.git --exclude-dir=node_modules \
      --exclude=KEYMAP.md --exclude=MAPPING.md --exclude=AUDIT.md \
      --exclude="$(basename "${BASH_SOURCE[0]}")" 2>/dev/null | head -5)
done

echo "== sensitive paths that must never be vendored =="
for p in .ssh id_rsa id_ed25519 known_hosts .netrc docker/config.json .aws gh/hosts.yml; do
  found=$(find . -path ./.git -prune -o -name "*$p*" -print 2>/dev/null | head -3)
  [[ -n $found ]] && fail "sensitive path present: $found"
done

echo "== result: $HITS potential hits =="
exit $(( HITS > 0 ))
