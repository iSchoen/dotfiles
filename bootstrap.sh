#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
STOW_PACKAGES=(bash xcompose git nvim hypr waybar walker mako alacritty ghostty kitty starship btop fastfetch lazygit tmux mise omarchy)

echo "==> Dotfiles bootstrap starting..."
echo "    Dotfiles directory: $DOTFILES_DIR"

# --- Install stow ---
echo "==> Installing stow..."
sudo pacman -S --needed --noconfirm stow

# --- Restore packages ---
echo "==> Restoring official packages..."
sudo pacman -S --needed --noconfirm - < "$DOTFILES_DIR/pkglist.txt"

if [[ -s "$DOTFILES_DIR/aurlist.txt" ]]; then
  echo "==> Restoring AUR packages (requires yay)..."
  if command -v yay &>/dev/null; then
    yay -S --needed --noconfirm - < "$DOTFILES_DIR/aurlist.txt"
  else
    echo "    WARNING: yay not found, skipping AUR packages."
    echo "    Install yay and then run: yay -S --needed - < $DOTFILES_DIR/aurlist.txt"
  fi
fi

# --- Remove default configs that conflict with stow ---
echo "==> Removing default configs that would conflict with stow..."
rm -f ~/.bashrc ~/.bash_profile ~/.bash_logout ~/.XCompose
for pkg in "${STOW_PACKAGES[@]}"; do
  if [[ "$pkg" == "bash" || "$pkg" == "xcompose" || "$pkg" == "starship" ]]; then
    continue  # already handled above or handled differently
  fi
  rm -rf ~/.config/"$pkg"
done
rm -f ~/.config/starship.toml

# --- Stow all packages ---
echo "==> Stowing packages..."
cd "$DOTFILES_DIR"
for pkg in "${STOW_PACKAGES[@]}"; do
  echo "    Stowing $pkg..."
  stow "$pkg"
done

# --- Install pacman hook ---
echo "==> Installing pacman hook for auto-updating package lists..."
sudo mkdir -p /etc/pacman.d/hooks
sudo cp "$DOTFILES_DIR/hooks/pkglist.hook" /etc/pacman.d/hooks/pkglist.hook

echo "==> Done! All dotfiles restored."
