# ThemeDotFiles

Personal dotfiles for config and shell setup.

## Quick Setup (New PC)

```bash
git clone "<your-repo-url>" "$HOME/ThemeDotFiles"
cd "$HOME/ThemeDotFiles"
./scripts/setup-dotfiles.sh --dry-run
./scripts/setup-dotfiles.sh
```

## What the setup script does

- Symlinks each top-level folder in `dot-config-files/` to `~/.config/`
- Symlinks `dot-zshrc` to `~/.zshrc`
- Backs up existing real files/folders before replacing them:
  - `~/.config/<name>.bak-YYYYMMDD-HHMMSS`
  - `~/.zshrc.bak-YYYYMMDD-HHMMSS`

## Options

```bash
./scripts/setup-dotfiles.sh --dry-run
./scripts/setup-dotfiles.sh --force
```

- `--dry-run`: preview actions without changing anything
- `--force`: replace conflicting symlinks that point somewhere else
