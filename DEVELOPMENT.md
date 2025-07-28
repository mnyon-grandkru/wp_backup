# Development Guide

## How To Use

### Creating a Backup

```bash
./wp_backup.zsh
```

This will:
- Create a timestamped backup on the remote server
- Download the backup files to your local machine
- Clean up old remote backups (older than 7 days)

### Restoring from a Backup

```bash
./wp_restore.zsh <backup-timestamp>
```

Example:
```bash
./wp_restore.zsh 2025-01-20_14-30-00
```

This will:
- Upload the backup files to the remote server
- Restore the database using wp-cli
- Restore the site files
- Clean up temporary files on the remote server

### Listing Available Backups

```bash
./wp_restore.zsh -l
# or
./wp_restore.zsh --list
```

This will display a table showing:
- Site name
- Backup date (timestamp)
- Size of the backup
- Full path to the backup directory

## Requirements

- SSH access to the remote server
- wp-cli installed on the remote server
- zsh shell (scripts are written for zsh)

## File Structure

```
wp_backups/
├── 2025-01-20_14-30-00/
│   ├── db_backup_2025-01-20_14-30-00.sql
│   └── files_backup_2025-01-20_14-30-00.tar.gz
└── ...
```

## Security Notes

- The `.env` file contains sensitive information and is ignored by git
- Make sure your SSH keys are properly configured for passwordless access
- Consider using SSH config files for easier server management