#!/bin/sh
nix-channel --add https://nixos.org/channels/nixpkgs-unstable
nix-channel --update

nix profile install \
      --extra-experimental-features flakes \
      --extra-experimental-features nix-command
      --accept-flake-config \
      'github:flox/flox'
