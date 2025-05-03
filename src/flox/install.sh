#!/bin/sh
set -e

echo "Installing Flox"

RUN echo 'extra-trusted-substituters = https://cache.flox.dev' | sudo tee -a /etc/nix/nix.conf && \
    echo 'extra-trusted-public-keys = flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs=' | sudo tee -a /etc/nix/nix.conf

nix profile install github:flox/flox \
    --extra-experimental-features flakes \
    --extra-experimental-features nix-command \
    --accept-flake-config

flox --version

echo "Installed Flox"
