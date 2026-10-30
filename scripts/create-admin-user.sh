#!/usr/bin/env bash
# create-admin-user.sh - creates a hardened admin user
#sudo ./create-admin-user.sh <admin> <public-key-file>

# 2. Stop on the first error
set -euo pipefail

user="${1:-}"      # first argument: the username
keyfile="${2:-}"   # second argument: the public key file

# 3. Must be run as root

if [ "$EUID" -ne 0 ]; then
echo "Error: run this with sudo." >&2
exit 1
fi

# 4. Check both arguments, the key file exists and starts with ssh-

if [ -z "$user" ]|| [ -z "$keyfile" ]; then
echo "Usage: sudo $0 <username> <public-key-file>" >&2
exit 1
fi
if [ ! -f "$keyfile" ]; then
echo "Error:key file $keyfile not found." >&2
exit 1
fi
if ! grep -q '^ssh-' "$keyfile"; then
echo "Error: $keyfile is not a public SSH key." >&2
exit
fi
# 5. Create the user if they don't exist (no password)
if id "$user" &>/dev/null; then
echo "User $user already exists, skipping."
else
adduser --disabled-password --gecos "" "$user"
echo "Set a password for $user (used only for sudo):"
passwd "$user"
fi
# 6. Create the devops group if missing; add user to sudo and devops
if ! getent group devops >/dev/null; then
groupadd devops
echo "Created group devops"
fi
usermod -aG sudo,devops "$user"
echo "Added $user to sudo and devops"
# 7. Install the key with correct owner and permissions
home_dir=$(getent passwd "$user" | cut -d: -f6)
install -d -m 700 -o "$user" -g "$user" "$home_dir/.ssh"
install -m 600 -o "$user" -g "$user" "$keyfile" "$home_dir/.ssh/authorized_keys"
echo "Installed SSH key for $user."
# 8. Write the SSH hardening file, test with sshd -t, restart only if OK
cat > /etc/ssh/sshd_config.d/00-hardening.conf <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
EOF

if sshd -t; then
systemctl restart ssh
echo "SSH config valid, service restarted."
else 
echo "Error; SSH config test failed. SSH NOT restarted." >&2
exit 1
fi

echo "Done: $user is an admin with key-only SSH access."
