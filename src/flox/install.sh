#!/bin/sh
set -e

echo "Installing Flox"

echo 'extra-trusted-substituters = https://cache.flox.dev' | sudo tee -a /etc/nix/nix.conf
echo 'extra-trusted-public-keys = flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs=' | sudo tee -a /etc/nix/nix.conf

nix profile install \
    --profile /nix/var/nix/profiles/default \
    --experimental-features "nix-command flakes" \
    --accept-flake-config \
    'github:flox/flox'

flox --version

echo "Installed Flox"
