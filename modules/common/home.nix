{ pkgs, lib, ... }:
# Shared Home Manager configuration — imported by all OS modules.
{

  # --- packages ---

  home.packages = with pkgs; [
    # system utilities
    bat       
    curl
    htop
    rsync
    wget
    fastfetch

    # search & navigation
    fzf
    jq
    ripgrep

    # development
    git
    lazygit
    tmux
    tmuxinator
    direnv

    # security
    gnupg
    keychain

    # fonts
    nerd-fonts.fira-code
  ] ++ lib.optionals pkgs.stdenv.isLinux (with pkgs; [
    wezterm  # macOS: comes from the Homebrew cask in darwin.nix
  ]);

  # --- session / environment ---

  # Nix profile — in .zshenv so it is set before hm-session-vars.sh is sourced,
  # and for all shell invocation types (login, interactive, script).
  home.sessionPath = [
    "$HOME/.nix-profile/bin"
    "/nix/var/nix/profiles/default/bin"
  ];

  # --- zsh ---

  programs.zsh = {
    enable = true;

    autosuggestion.enable     = true;
    syntaxHighlighting.enable = true;

    envExtra = ''
      export PATH=$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH
      export PATH=$HOME/bin:/usr/local/bin:$HOME/.local/bin:$PATH
      export EDITOR=vim
    '';

    initContent = lib.mkMerge [
      # keychain zstyle must be set before oh-my-zsh is sourced (order 550 < compinit 600).
      (lib.mkOrder 550 ''
        zstyle :omz:plugins:keychain agents     gpg,ssh
        zstyle :omz:plugins:keychain identities github gitlab-is4s gitlab-aspn gitlab-antcenter gitlab-cps
      '')
      ''
        # cl: cd and ls combined
        function cl() {
          DIR="$*"
          if [ $# -lt 1 ]; then DIR=$HOME; fi
          builtin cd "''${DIR}" && ls -F --color=auto
        }

        # lg: lazygit — cd to repo on exit
        function lg() {
          export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
          lazygit "$@"
          if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
            cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
            rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
          fi
        }
      ''
    ];

    shellAliases = {
      # GNU coreutils flags — guarded so they don’t break macOS BSD tools
      ls  = lib.mkIf pkgs.stdenv.isLinux "ls --color=auto";
      ll  = lib.mkIf pkgs.stdenv.isLinux "ls -lah --color=auto";
      tcn = lib.mkIf pkgs.stdenv.isLinux "mv --force -t ~/.local/share/Trash/files";
      cpv = "rsync -ah --info=progress2";
      src = "source ~/.zshrc";
      mux = "tmuxinator";
    };

    oh-my-zsh = {
      enable  = true;
      theme   = "cloud";
      plugins = [
        "git"
        "history"
        "tmux"
        "gpg-agent"
        "keychain"
      ];
    };
  };

  # --- git ---

  programs.git = {
    enable  = true;
    settings = {
      user.name  = "Tanner Koza";
      user.email = "kozatanner@gmail.com";
      init.defaultBranch   = "main";
      pull.rebase          = false;
      push.autoSetupRemote = true;
      core.editor          = "vim";
    };
    ignores = [
      ".DS_Store"
      "*.swp"
      ".direnv"
      ".envrc"
    ];
  };

  # --- direnv ---

  programs.direnv = {
    enable            = true;
    nix-direnv.enable = true;
  };

  # --- tmux ---

  programs.tmux = {
    enable       = true;
    shell        = "${pkgs.zsh}/bin/zsh";
    terminal     = "screen-256color";
    historyLimit = 10000;
    keyMode      = "vi";
    prefix       = "C-a";
    mouse        = true;
    extraConfig  = ''
      # split panes using | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # vim-style pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # status bar at top
      set -g status-position top
    '';
  };  

  # --- wezterm ---
  # macOS: config still applies — wezterm binary comes from the Homebrew cask.

  xdg.configFile."wezterm/wezterm.lua".text = ''
    local wezterm = require 'wezterm'

    local config = {}

    if wezterm.config_builder then
      config = wezterm.config_builder()
    end

    config.keys = {
      {
        key = 'Enter',
        mods = 'ALT',
        action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
      },
      {
        key = 'Enter',
        mods = 'SHIFT|ALT',
        action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
      },
      {
        key = "h",
        mods = "ALT|SHIFT",
        action = wezterm.action.ActivatePaneDirection("Left"),
      },
      {
        key = "l",
        mods = "ALT|SHIFT",
        action = wezterm.action.ActivatePaneDirection("Right"),
      },
      {
        key = "k",
        mods = "ALT|SHIFT",
        action = wezterm.action.ActivatePaneDirection("Up"),
      },
      {
        key = "j",
        mods = "ALT|SHIFT",
        action = wezterm.action.ActivatePaneDirection("Down"),
      },
      {
        key = "h",
        mods = "CTRL|SHIFT",
        action = wezterm.action.ActivateTabRelative(-1),
      },
      {
        key = "l",
        mods = "CTRL|SHIFT",
        action = wezterm.action.ActivateTabRelative(1),
      },
    }

    return config
  '';

}