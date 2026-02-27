#!/usr/bin/env bash
set -euo pipefail

USER="colony"
HOME_DIR="/home/${USER}"
SSH_DIR="${HOME_DIR}/.ssh"

# --- SSH Public Key ---
if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
    echo "$SSH_PUBLIC_KEY" > "${SSH_DIR}/authorized_keys"
    chown "${USER}:${USER}" "${SSH_DIR}/authorized_keys"
    chmod 600 "${SSH_DIR}/authorized_keys"
    echo "[entrypoint] SSH public key written to authorized_keys"
else
    echo "[entrypoint] WARNING: SSH_PUBLIC_KEY not set, SSH login will not work"
fi

# --- SSH Host Keys ---
ssh-keygen -A
echo "[entrypoint] SSH host keys generated"

# --- ZeroTier ---
if [ -n "${ZEROTIER_NETWORK:-}" ]; then
    echo "[entrypoint] Starting ZeroTier and joining network ${ZEROTIER_NETWORK}"
    zerotier-one -d
    # Wait for the service to be ready
    while ! zerotier-cli info >/dev/null 2>&1; do
        sleep 0.5
    done
    zerotier-cli join "$ZEROTIER_NETWORK"
    echo "[entrypoint] Joined ZeroTier network ${ZEROTIER_NETWORK}"
    # Stop the daemon — supervisor will manage it from here
    zerotier-cli shutdown || true
    sleep 1
else
    echo "[entrypoint] WARNING: ZEROTIER_NETWORK not set, skipping ZeroTier"
fi

# Hand off to supervisord
exec supervisord -n -c /etc/supervisor/supervisord.conf
