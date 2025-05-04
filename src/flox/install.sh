#!/bin/bash
set -e

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"

detect_user() {
    local user_variable_name=${1:-username}
    local possible_users=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    if [ "${!user_variable_name}" = "auto" ] || [ "${!user_variable_name}" = "automatic" ]; then
        declare -g ${user_variable_name}=""
        for current_user in ${possible_users[@]}; do
            if id -u "${current_user}" > /dev/null 2>&1; then
                declare -g ${user_variable_name}="${current_user}"
                break
            fi
        done
    fi
    if [ "${!user_variable_name}" = "" ] || [ "${!user_variable_name}" = "none" ] || ! id -u "${!user_variable_name}" > /dev/null 2>&1; then
        declare -g ${user_variable_name}=root
    fi
}

detect_user USERNAME

echo "Installing Flox for user ${USERNAME}"

echo 'extra-trusted-substituters = https://cache.flox.dev' | tee -a /etc/nix/nix.conf
echo 'extra-trusted-public-keys = flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs=' | tee -a /etc/nix/nix.conf

# Ensure nix-users group exists and user is a member (needed for multi-user nix daemon access)
if ! getent group nix-users > /dev/null; then
    groupadd --system nix-users
fi
if [ "${USERNAME}" != "root" ]; then
    usermod -aG nix-users ${USERNAME}
fi

# Execute nix commands as user, explicitly setting PATH and sourcing environment
NIX_BIN_DIR="/nix/var/nix/profiles/default/bin"
NIX_ENV_SCRIPT="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"

# su ${USERNAME} -c "export PATH=\"${NIX_BIN_DIR}:\$PATH\"; . \"${NIX_ENV_SCRIPT}\"; nix profile install \
#     --profile /nix/var/nix/profiles/default \
#     --experimental-features \"nix-command flakes\" \
#     --accept-flake-config \
#     'github:flox/flox'"

nix profile install \
    --profile /nix/var/nix/profiles/default \
    --experimental-features "nix-command flakes" \
    --accept-flake-config \
    'github:flox/flox'

flox --version

su ${USERNAME} -c "export PATH=\"${NIX_BIN_DIR}:\$PATH\"; . \"${NIX_ENV_SCRIPT}\"; flox --version"
su ${USERNAME} -c "flox --version"

echo "Installed Flox for user ${USERNAME}"
