#!/bin/sh
nix profile install \
    --extra-experimental-features flakes \
    --extra-experimental-features nix-command \
    --accept-flake-config \
    'github:flox/flox'
