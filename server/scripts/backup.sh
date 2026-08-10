#!/bin/bash
set -e

BACKUP_DIR="/tmp/scamguard_backups"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILE_NAME="db_backup_${TIMESTAMP}.sql"
DB_NAME="scamguard_db"
DB_USER="admin"

echo "Starting backup of ${DB_NAME}..."
pg_dump -U ${DB_USER} -d ${DB_NAME} -f "${BACKUP_DIR}/${FILE_NAME}"

# Encrypt backup
# Using symmetric encryption with openssl
ENCRYPTION_PASS=${BACKUP_PASSWORD:-"supersecret123"}
openssl enc -aes-256-cbc -salt -in "${BACKUP_DIR}/${FILE_NAME}" -out "${BACKUP_DIR}/${FILE_NAME}.enc" -pass pass:${ENCRYPTION_PASS}

# Cleanup unencrypted
rm "${BACKUP_DIR}/${FILE_NAME}"

echo "Backup completed: ${BACKUP_DIR}/${FILE_NAME}.enc"
