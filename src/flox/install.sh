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

# Start the nix-daemon if it's not already running (needed for multi-user install during build)
if ! pgrep -x nix-daemon > /dev/null; then
    echo "Starting nix-daemon..."
    # Source the environment for the daemon and run it in the background
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    /nix/var/nix/profiles/default/bin/nix-daemon > /tmp/nix-daemon-build.log 2>&1 &
    # Wait a moment for the daemon to start and the socket to be available
    sleep 5
    echo "Checking daemon status..."
    if ! pgrep -x nix-daemon > /dev/null; then
        echo "(!) Failed to start nix-daemon during build."
        cat /tmp/nix-daemon-build.log || echo "No log file found."
        # Optionally exit here if daemon is critical, or proceed cautiously
        # exit 1 
    else
        echo "nix-daemon started successfully."
    fi
else
    echo "nix-daemon already running."
fi


su ${USERNAME} -c ". /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && nix profile install \
    --profile /nix/var/nix/profiles/default \
    --experimental-features \"nix-command flakes\" \
    --accept-flake-config \
    'github:flox/flox'"

su ${USERNAME} -c ". /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && flox --version"

echo "Installed Flox for user ${USERNAME}"
