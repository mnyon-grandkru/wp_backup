#!/bin/zsh

# === Load .env file ===
ENV_FILE="${0:A:h}/.env"
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs)
else
  echo "❌ .env file not found at $ENV_FILE"
  exit 1
fi

# === Function to list available backups ===
list_backups() {
  echo "📋 Available local backups:"
  echo ""

  if [ ! -d "$LOCAL_BACKUP_DIR" ]; then
    echo "❌ Local backup directory not found: $LOCAL_BACKUP_DIR"
    exit 1
  fi

  # Extract site name from LOCAL_BACKUP_DIR path
  SITE_NAME=$(basename "$LOCAL_BACKUP_DIR")

  # Find all backup directories and sort by date (newest first)
  BACKUP_DIRS=$(find "$LOCAL_BACKUP_DIR" -maxdepth 1 -type d -name "20*" | sort -r)

  if [ -z "$BACKUP_DIRS" ]; then
    echo "❌ No backups found in $LOCAL_BACKUP_DIR"
    exit 1
  fi

        printf "%-15s %-25s %-20s %-8s %s\n" "SITE" "DATE" "TIMESTAMP" "SIZE" "PATH"
  printf "%-15s %-25s %-20s %-8s %s\n" "----" "----" "---------" "----" "----"

  while IFS= read -r backup_dir; do
    if [ -n "$backup_dir" ]; then
      timestamp=$(basename "$backup_dir")

      # Convert timestamp to user-friendly date format
      # Input format: 2025-07-21_14-51-29
      # Output format: Jul 21, 2025 at 2:51 PM
      if [[ "$timestamp" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})_([0-9]{2})-([0-9]{2})-([0-9]{2})$ ]]; then
        year="${match[1]}"
        month="${match[2]}"
        day="${match[3]}"
        hour="${match[4]}"
        minute="${match[5]}"

        # Convert month number to name
        case $month in
          01) month_name="Jan" ;;
          02) month_name="Feb" ;;
          03) month_name="Mar" ;;
          04) month_name="Apr" ;;
          05) month_name="May" ;;
          06) month_name="Jun" ;;
          07) month_name="Jul" ;;
          08) month_name="Aug" ;;
          09) month_name="Sep" ;;
          10) month_name="Oct" ;;
          11) month_name="Nov" ;;
          12) month_name="Dec" ;;
        esac

        # Convert 24-hour to 12-hour format
        if [ "$hour" -eq "00" ]; then
          friendly_hour="12"
          ampm="AM"
        elif [ "$hour" -lt "12" ]; then
          friendly_hour="$hour"
          ampm="AM"
        elif [ "$hour" -eq "12" ]; then
          friendly_hour="12"
          ampm="PM"
        else
          friendly_hour=$((hour - 12))
          ampm="PM"
        fi

        # Remove leading zero from day and hour
        friendly_day=$(echo "$day" | sed 's/^0//')
        friendly_hour=$(echo "$friendly_hour" | sed 's/^0//')

        friendly_date="$month_name $friendly_day, $year at $friendly_hour:$minute $ampm"
      else
        friendly_date="$timestamp"
      fi

      # Calculate total size of backup directory
      if [ -d "$backup_dir" ]; then
        size=$(du -sh "$backup_dir" 2>/dev/null | awk '{print $1}')
      else
        size="N/A"
      fi

      printf "%-15s %-25s %-20s %-8s %s\n" "$SITE_NAME" "$friendly_date" "$timestamp" "$size" "$backup_dir"
    fi
  done <<< "$BACKUP_DIRS"

  echo ""
  echo "Usage: $0 <backup-timestamp>"
  echo "Example: $0 2025-07-20_23-59-00"
}

# === Check for list argument ===
if [ "$1" = "-l" ] || [ "$1" = "--list" ]; then
  list_backups
  exit 0
fi

# === Input: Backup timestamp to restore ===
if [ -z "$1" ]; then
  echo "Usage: $0 <backup-timestamp>"
  echo "       $0 -l|--list"
  echo "Example: $0 2025-07-20_23-59-00"
  exit 1
fi

TIMESTAMP="$1"
DB_BACKUP="db_backup_${TIMESTAMP}.sql"
FILES_BACKUP="files_backup_${TIMESTAMP}.tar.gz"

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
