# Security & privacy notes

This repo is published. Before the first commit — and before every push — a
scrub pass was/was run:

## What was redacted or excluded

- Real Linux username in any path → `$HOME` / `~` / placeholders
- Hostname, machine-id, MAC/serial numbers → stripped from audit docs
- SSH private keys, authorized_keys, known_hosts → never vendored; backups only
- API tokens (Jan LLM env block found in `.zshenv`, git credentials, etc.) →
  never copied into this repo; they exist only on the machine and in backups
- Personal wallpapers/photos → not included; themes ship upstream artwork only
- `~/.aws`, `~/.config/gh`, docker logins, `.netrc` → never swept into repo

## What a new user must supply themselves

Nothing is required for the desktop to work. Optional integrations you may add
on your own machine (never commit them):

- any tokens your own scripts need → put them in
  `~/.config/de-omarchy/secrets.env` (gitignored pattern below) and source it
  from your shell rc

## Tooling

- `scripts/scan-secrets.sh` runs gitleaks (if installed) plus targeted greps
  for keys, tokens, bearer headers, hardcoded `/home/<user>` paths.
- Run it before **every** commit/push: `./scripts/scan-secrets.sh`
- If a real secret ever lands in history: rotate the credential immediately,
  then rewrite history (`git filter-repo`) or start a fresh repo — removing it
  in a later commit does NOT remove it from history.

## Backups are radioactive by design

`~/.de-omarchy-backups/` contains full copies of real dotfiles including
secrets. It lives outside this repo, must never be committed, and should sit on
an encrypted or physically secure volume.
