{ ... }:
# macOS (nix-darwin).
# Apply: darwin-rebuild switch --flake ~/.config/nix#$(nix eval --raw nixpkgs#stdenv.hostPlatform.system)
{
  # Allow unfree packages (VS Code, etc.)
  nixpkgs.config.allowUnfree = true;

  # --- system defaults ---

  system.defaults = {
    dock = {
      autohide     = true;
      orientation  = "bottom";
      show-recents = false;
    };
    finder = {
      ShowPathbar                    = true;
      ShowStatusBar                  = true;
      FXEnableExtensionChangeWarning = false;
    };
    NSGlobalDomain = {
      KeyRepeat              = 2;
      InitialKeyRepeat       = 15;
      AppleShowAllExtensions = true;
    };
  };

  # --- default terminal ---

  environment.variables.TERMINAL = "wezterm";

  # --- security ---

  # Allow Touch ID to authenticate sudo prompts.
  security.pam.enableSudoTouchIdAuth = true;

  # --- homebrew --- (GUI apps; `zap` removes unlisted casks on each switch)

  homebrew = {
    enable                  = true;
    onActivation.cleanup    = "zap";
    casks = [
      "brave-browser"
      "spotify"
      "visual-studio-code"
      "wezterm"
    ];
  };

  # --- home manager ---

  home-manager.useGlobalPkgs   = true;
  home-manager.useUserPackages = true;
  home-manager.users.kozaxo = {
    imports           = [ ./common/home.nix ];
    home.stateVersion = "24.11";
  };
}
