#!/bin/zsh

# === Load .env file ===
ENV_FILE="${0:A:h}/.env"
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs)
else
  echo "❌ .env file not found at $ENV_FILE"
  exit 1
fi

# === Dynamic Variables ===
DATE=$(date +'%Y-%m-%d_%H-%M-%S')
DB_BACKUP="db_backup_$DATE.sql"
FILES_BACKUP="files_backup_$DATE.tar.gz"

# === SSH COMMAND WRAPPER ===
ssh_cmd() {
  ssh "${REMOTE_USER}@${REMOTE_HOST}" "$1"
}

# === RUN BACKUP COMMANDS ON REMOTE ===
echo "🔁 Creating backup on remote server..."

# Ensure remote backup directory exists
ssh_cmd "mkdir -p ~/${REMOTE_BACKUP_DIR}"

# Export DB using wp-cli
ssh_cmd "cd ~/${REMOTE_WP_PATH} && wp db export ~/${REMOTE_BACKUP_DIR}/${DB_BACKUP} --quiet"

# Archive site files, excluding the backup directory
ssh_cmd "cd ~ && tar --exclude=${REMOTE_BACKUP_DIR} -czf ${REMOTE_BACKUP_DIR}/${FILES_BACKUP} ${REMOTE_WP_PATH}"

# === DOWNLOAD TO LOCAL MACHINE ===
echo "⬇️ Downloading backup to local machine..."

LOCAL_DATE_DIR="${LOCAL_BACKUP_DIR}/${DATE}"
mkdir -p "${LOCAL_DATE_DIR}"

scp "${REMOTE_USER}@${REMOTE_HOST}:~/${REMOTE_BACKUP_DIR}/${DB_BACKUP}" "${LOCAL_DATE_DIR}/"
scp "${REMOTE_USER}@${REMOTE_HOST}:~/${REMOTE_BACKUP_DIR}/${FILES_BACKUP}" "${LOCAL_DATE_DIR}/"

# === CLEANUP OLD REMOTE BACKUPS (older than 7 days) ===
echo "🧹 Cleaning up old remote backups..."
ssh_cmd "find ~/${REMOTE_BACKUP_DIR} -type f -mtime +7 -delete"

echo "✅ Backup completed and saved to: ${LOCAL_DATE_DIR}"
