# nix-audiorelay

Nix flake packaging [AudioRelay](https://audiorelay.net) for NixOS/Linux — stream audio from your PC to your phone (or vice versa).

## Quick run (no install)

```bash
nix run github:yourusername/nix-audiorelay
```

---

## Add to your dotfiles

### 1. Add the flake input

In your `flake.nix`:

```nix
inputs = {
  nix-audiorelay = {
    url = "github:yourusername/nix-audiorelay";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

---

### Option A — NixOS module

Pass the module to your NixOS configuration and enable it:

```nix
# flake.nix outputs
nixosConfigurations.myhostname = nixpkgs.lib.nixosSystem {
  modules = [
    inputs.nix-audiorelay.nixosModules.audiorelay
    {
      programs.audiorelay.enable = true;
    }
  ];
};
```

---

### Option B — Home Manager module

Pass the module to your Home Manager configuration and enable it:

```nix
# flake.nix outputs
homeConfigurations.myuser = home-manager.lib.homeManagerConfiguration {
  modules = [
    inputs.nix-audiorelay.homeManagerModules.audiorelay
    {
      programs.audiorelay.enable = true;
    }
  ];
};
```

---

### Option C — Overlay (manual package)

Add the overlay to nixpkgs and use `pkgs.audiorelay` directly:

```nix
nixpkgs.overlays = [ inputs.nix-audiorelay.overlays.default ];
nixpkgs.config.allowUnfree = true;

# Then anywhere in your config:
environment.systemPackages = [ pkgs.audiorelay ];   # NixOS
# or
home.packages = [ pkgs.audiorelay ];                # Home Manager
```

---

## Updating to a new version

1. Find the latest release at https://community.audiorelay.net/c/releases/9
2. Update `version` in `flake.nix`
3. Get the new hash:
   ```bash
   nix-prefetch-url --type sha256 \
     https://dl.audiorelay.net/setups/linux/audiorelay-<version>-x64.tar.gz
   # Convert to SRI format:
   nix hash convert --hash-algo sha256 --to sri <hash>
   ```
4. Update the `hash` field in `flake.nix`
5. Run `nix build` to verify
