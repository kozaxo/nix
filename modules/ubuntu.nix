{ pkgs, lib, ... }:
# Ubuntu — standalone Home Manager.
# Apply: home-manager switch --flake ~/.config/nix#$(nix eval --raw nixpkgs#stdenv.hostPlatform.system)
{
  imports = [ ./common/home.nix ./common/gnome.nix ];

  # --- identity ---

  home.username      = "kozaxo";
  home.homeDirectory = "/home/kozaxo";
  home.stateVersion  = "24.11";

  # Required for standalone Home Manager on non-NixOS Linux.
  targets.genericLinux.enable = true;

  # --- packages ---

  home.packages = with pkgs; [
    home-manager   # pin hm binary in the profile so it persists after every switch
    podman
    podman-compose
  ];

  # --- programs ---

  programs.vscode.enable = true;

  # --- activations ---

  # -- brave browser --
  # Installed via apt: the Nix brave package requires its SUID sandbox helper
  # to be owned by root (mode 4755), which Nix cannot set on non-NixOS Linux.
  home.activation.installBrave = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.writeShellScript "install-brave" ''
      set -euo pipefail
      if [ -x /usr/bin/brave-browser ]; then
        echo "Brave browser already installed, skipping."
        exit 0
      fi
      echo "Installing Brave browser via apt..."
      /usr/bin/sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
        https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
      echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" \
        | /usr/bin/sudo tee /etc/apt/sources.list.d/brave-browser-stable.list
      /usr/bin/sudo apt-get update -qq
      /usr/bin/sudo apt-get install -y brave-browser
      echo "Brave browser installed."
    ''}
  '';

  # -- default shell --
  # Registers the Nix-managed zsh in /etc/shells and sets it as the login shell.
  home.activation.setDefaultShell = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.writeShellScript "set-default-shell" ''
      set -euo pipefail
      ZSH="${pkgs.zsh}/bin/zsh"
      if ! /usr/bin/grep -qxF "$ZSH" /etc/shells 2>/dev/null; then
        echo "Adding $ZSH to /etc/shells"
        echo "$ZSH" | /usr/bin/sudo tee -a /etc/shells
      fi
      CURRENT_SHELL="$(/usr/bin/getent passwd "$USER" | /usr/bin/cut -d: -f7)"
      if [ "$CURRENT_SHELL" != "$ZSH" ]; then
        echo "Changing login shell to $ZSH"
        /usr/bin/sudo chsh -s "$ZSH" "$USER"
      else
        echo "Login shell is already $ZSH, skipping."
      fi
    ''}
  '';

  # -- default terminal --
  # GNOME resolves the default terminal via update-alternatives, not $TERMINAL.
  home.activation.setDefaultTerminal = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.writeShellScript "set-default-terminal" ''
      set -euo pipefail
      TERMINAL="${pkgs.wezterm}/bin/wezterm"
      if ! /usr/bin/update-alternatives --query x-terminal-emulator >/dev/null 2>&1; then
        echo "update-alternatives not found, skipping."
        exit 0
      fi
      CURRENT="$(/usr/bin/update-alternatives --query x-terminal-emulator 2>/dev/null | /usr/bin/awk '/^Value:/{print $2}')"
      if [ "$CURRENT" = "$TERMINAL" ]; then
        echo "Default terminal is already $TERMINAL, skipping."
        exit 0
      fi
      echo "Setting default terminal to $TERMINAL"
      /usr/bin/sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$TERMINAL" 100
      /usr/bin/sudo update-alternatives --set x-terminal-emulator "$TERMINAL"
    ''}
  '';

  # -- completion message --
  home.activation.completionMessage = lib.hm.dag.entryAfter ["setDefaultShell" "setDefaultTerminal" "installBrave"] ''
    ${pkgs.writeShellScript "completion-message" ''
      echo ""
      echo "====================================================="
      echo "  Installation complete."
      echo ""
      echo "  You may need to logout if:"
      echo "    - modifying desktop environment"
      echo "    - modifying shell settings"
      echo "====================================================="
      echo ""
    ''}
  '';

}

