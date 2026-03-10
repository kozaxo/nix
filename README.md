# nix configuration

Cross-platform system configuration for **kozaxo** managed with Nix, Home Manager, and nix-darwin.

## Structure

```
nix/
├── flake.nix                  # wires everything together
└── modules/
    ├── common/
    │   └── home.nix           # dotfiles & packages shared across all OSes
    │   └── gnome.nix          # GNOME desktop environment configuration
    ├── ubuntu.nix             # Ubuntu — standalone Home Manager
    ├── darwin.nix             # macOS — nix-darwin + Home Manager
    └── nixos.nix              # NixOS — system config + Home Manager
```

---

## Fresh Machine Setup

### Ubuntu

1. Install Nix (multi-user daemon mode):

   ```bash
   sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
   ```

2. Follow the `home-manager` [installation guide](https://nix-community.github.io/home-manager/index.xhtml#sec-install-standalone).

3. Clone this repo:

   ```bash
   git clone https://github.com/kozaxo/nix.git ~/.config/nix
   ```

4. Open a new terminal, then enable flakes:

   ```bash
   echo "experimental-features = nix-command flakes" | tee -a ~/.config/nix/nix.conf
   ```

5. Apply:

   ```bash
   home-manager switch --flake ~/.config/nix#$(nix eval --raw nixpkgs#stdenv.hostPlatform.system)
   ```

6. Log out and back in so the new login shell (zsh) and PATH take effect.

---

### macOS

1. Install Nix (multi-user daemon mode):

   ```bash
   sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
   ```

2. Open a new terminal, then enable flakes:

   ```bash
   mkdir -p ~/.config/nix
   echo "experimental-features = nix-command flakes" | tee -a ~/.config/nix/nix.conf
   ```

3. Install Homebrew (required for GUI app casks — Brave, Spotify, VS Code, WezTerm):

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

4. Clone this repo:

   ```bash
   git clone https://github.com/kozaxo/nix-config.git ~/.config/nix
   ```

5. Apply:

   ```bash
   nix run nix-darwin -- switch --flake ~/.config/nix#$(nix eval --raw nixpkgs#stdenv.hostPlatform.system)
   ```

---

### NixOS

NixOS manages flakes natively. After installation, enable flakes in `/etc/nixos/configuration.nix`:

```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

1. Clone this repo:

   ```bash
   git clone https://github.com/kozaxo/nix-config.git ~/.config/nix
   ```

2. Apply:

   ```bash
   sudo nixos-rebuild switch --flake ~/.config/nix#$(nix eval --raw nixpkgs#stdenv.hostPlatform.system)
   ```

---

## Applying Changes

| Platform | Command                                                                                                |
| -------- | ------------------------------------------------------------------------------------------------------ |
| Ubuntu   | `home-manager switch --flake ~/.config/nix#$(nix eval --raw nixpkgs#stdenv.hostPlatform.system)`       |
| macOS    | `darwin-rebuild switch --flake ~/.config/nix#$(nix eval --raw nixpkgs#stdenv.hostPlatform.system)`     |
| NixOS    | `sudo nixos-rebuild switch --flake ~/.config/nix#$(nix eval --raw nixpkgs#stdenv.hostPlatform.system)` |

---

## Adding Packages

| Where                                              | Effect            |
| -------------------------------------------------- | ----------------- |
| `modules/common/home.nix` → `home.packages`        | All platforms     |
| `modules/ubuntu.nix` → `home.packages`             | Ubuntu only       |
| `modules/darwin.nix` → `homebrew.casks`            | macOS GUI apps    |
| `modules/nixos.nix` → `environment.systemPackages` | NixOS system-wide |

Search packages at <https://search.nixos.org/packages>.
