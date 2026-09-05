#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: ./restore.sh <backup_file.enc>"
    exit 1
fi

ENCRYPTED_FILE="$1"
if [ ! -f "$ENCRYPTED_FILE" ]; then
    echo "Error: File $ENCRYPTED_FILE not found!"
    exit 1
fi

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

DB_NAME="${POSTGRES_DB:-scamguard_db}"
DB_USER="${POSTGRES_USER:-admin}"
DECRYPTED_FILE="/tmp/scamguard_restore.sql"
ENCRYPTION_PASS="${BACKUP_PASSWORD}"

echo "Decrypting backup file..."
openssl enc -d -aes-256-cbc -in "${ENCRYPTED_FILE}" -out "${DECRYPTED_FILE}" -pass pass:${ENCRYPTION_PASS}

echo "Restoring database ${DB_NAME}..."
# In a real scenario we might drop and recreate the DB, or just run the SQL if it has DROP statements
psql -U ${DB_USER} -d ${DB_NAME} -f "${DECRYPTED_FILE}"

echo "Cleaning up..."
rm "${DECRYPTED_FILE}"

echo "Restore completed successfully."
