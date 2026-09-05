#!/bin/bash
set -e

BACKUP_DIR="/tmp/scamguard_backups"
mkdir -p "$BACKUP_DIR"

cd "$(dirname "$0")/.."

# โหลดค่าคอนฟิกจาก .env.local หรือ .env
if [ -f .env.local ]; then
    set -a
    source .env.local
    set +a
elif [ -f .env ]; then
    set -a
    source .env
    set +a
fi

if [ -z "$BACKUP_PASSWORD" ]; then
    echo "Error: BACKUP_PASSWORD must be defined in .env or environment"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILE_NAME="db_backup_${TIMESTAMP}.sql"
DB_NAME="${POSTGRES_DB:-scamguard_db}"
DB_USER="${POSTGRES_USER:-admin}"

echo "Starting backup of ${DB_NAME}..."
pg_dump -U ${DB_USER} -d ${DB_NAME} -f "${BACKUP_DIR}/${FILE_NAME}"

# Encrypt backup
# Using symmetric encryption with openssl
ENCRYPTION_PASS="${BACKUP_PASSWORD}"
openssl enc -aes-256-cbc -salt -in "${BACKUP_DIR}/${FILE_NAME}" -out "${BACKUP_DIR}/${FILE_NAME}.enc" -pass pass:${ENCRYPTION_PASS}

# Cleanup unencrypted
rm "${BACKUP_DIR}/${FILE_NAME}"

echo "Backup completed: ${BACKUP_DIR}/${FILE_NAME}.enc"
