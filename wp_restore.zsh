#!/bin/zsh

# === Input: Backup timestamp to restore ===
if [ -z "$1" ]; then
  echo "Usage: $0 <backup-timestamp>"
  echo "Example: $0 2025-07-20_23-59-00"
  exit 1
fi

TIMESTAMP="$1"
DB_BACKUP="db_backup_${TIMESTAMP}.sql"
FILES_BACKUP="files_backup_${TIMESTAMP}.tar.gz"

# === Variables (must match backup script) ===
REMOTE_USER="your_remote_user"
REMOTE_HOST="your.remote.host"
REMOTE_BACKUP_DIR="backups"
REMOTE_WP_PATH="public_html/your_wp_site"

LOCAL_BACKUP_DIR="/path/to/local/backups"

# === SSH COMMAND WRAPPER ===
ssh_cmd() {
  ssh "${REMOTE_USER}@${REMOTE_HOST}" "$1"
}

echo "⬆️ Uploading backup files to remote server..."

scp "${LOCAL_BACKUP_DIR}/${TIMESTAMP}/${DB_BACKUP}" "${REMOTE_USER}@${REMOTE_HOST}:~/${REMOTE_BACKUP_DIR}/"
scp "${LOCAL_BACKUP_DIR}/${TIMESTAMP}/${FILES_BACKUP}" "${REMOTE_USER}@${REMOTE_HOST}:~/${REMOTE_BACKUP_DIR}/"

echo "🔄 Restoring database..."
ssh_cmd "cd ~/${REMOTE_WP_PATH} && wp db import ~/${REMOTE_BACKUP_DIR}/${DB_BACKUP} --quiet"

echo "📦 Restoring site files..."
ssh_cmd "tar -xzf ~/${REMOTE_BACKUP_DIR}/${FILES_BACKUP} -C ~ --overwrite"

echo "🧹 Cleaning up uploaded backup files on remote server..."
ssh_cmd "rm ~/${REMOTE_BACKUP_DIR}/${DB_BACKUP} ~/${REMOTE_BACKUP_DIR}/${FILES_BACKUP}"

echo "✅ Restore completed!"
