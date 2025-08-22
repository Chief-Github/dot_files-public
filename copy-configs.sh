#!/bin/bash
echo "----------------------------------------------------"
echo "Copying files to specified folder"
echo "----------------------------------------------------"
DOTFILES_DIR="$HOME/public_dot_files/config"
cd "$DOTFILES_DIR" || { echo "Dotfiles directory not found!"; exit 1; }
CONFIGS_TO_BACKUP=(
    "hypr"
    "kitty"
    "ags"
    "waybar"
    "mako"
    "wofi"
    "Thunar"
    "neofetch"
    "starship.toml"
)

for config in "${CONFIGS_TO_BACKUP[@]}"; do
    echo "Syncing: $config"
    # Deleting old versions
    rm -rf "$DOTFILES_DIR/$config"
    # Copying new verison to ~/.config
    cp -r "$HOME/.config/$config" "$DOTFILES_DIR/"
done
echo "Syncing: .bashrc"
rm -f "$DOTFILES_DIR/.bashrc"
cp "$HOME/.bashrc" "$DOTFILES_DIR/"

echo "Syncing: .bashrc"
rm -f "$DOTFILES_DIR/.bashrc"
cp "$HOME/.bashrc" "$DOTFILES_DIR/"
echo "---------------------------------"
echo "--- Sync Complete! ---"
echo "--- now do - git add . ---"
echo "--- git commit -m 'update' ---"
echo "--- and git push !!! ---"
echo "---------------------------------"