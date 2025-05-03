#!/usr/bin/env bash
set -e

# Default username. Will be automatically detected if not set.
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

echo "Installing Flox for user ${USERNAME}"

# Configure Nix (system-wide, requires root)
echo 'extra-trusted-substituters = https://cache.flox.dev' | tee -a /etc/nix/nix.conf
echo 'extra-trusted-public-keys = flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs=' | tee -a /etc/nix/nix.conf

# Install Flox for the target user
USER_HOME_DIR=$(getent passwd ${USERNAME} | cut -d: -f6)
mkdir -p "${USER_HOME_DIR}/.local/state/nix/profile"
chown -R ${USERNAME}:${USERNAME} "${USER_HOME_DIR}/.local"

# Execute nix profile install as the target user
su ${USERNAME} -c "nix profile install \
    --experimental-features \"nix-command flakes\" \
    --accept-flake-config \
    'github:flox/flox'"

# Verify installation as the target user
su ${USERNAME} -c "flox --version"

echo "Installed Flox for user ${USERNAME}"
