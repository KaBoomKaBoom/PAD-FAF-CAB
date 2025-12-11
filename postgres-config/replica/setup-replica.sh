#!/bin/bash
set -e

echo "Starting replica setup..."
echo "PRIMARY_HOST: $PRIMARY_HOST"
echo "PRIMARY_PORT: $PRIMARY_PORT"
echo "REPLICA_SLOT_NAME: $REPLICA_SLOT_NAME"

# Wait for primary to be ready
MAX_RETRIES=30
RETRY_COUNT=0

until pg_isready -h $PRIMARY_HOST -p $PRIMARY_PORT -U $PGUSER; do
  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "ERROR: Primary database is not ready after $MAX_RETRIES attempts"
    exit 1
  fi
  echo "Waiting for primary database to be ready... (Attempt $RETRY_COUNT/$MAX_RETRIES)"
  sleep 3
done

echo "Primary is ready. Setting up replica..."

# Check if data directory is already initialized
if [ -f "/var/lib/postgresql/data/PG_VERSION" ]; then
    echo "Data directory already initialized. Starting PostgreSQL..."
else
    echo "Initializing replica from primary..."
    
    # Remove existing data directory if it exists
    rm -rf /var/lib/postgresql/data/*

    # Create base backup from primary with retry logic
    BACKUP_RETRIES=5
    BACKUP_COUNT=0
    BACKUP_SUCCESS=false

    while [ $BACKUP_COUNT -lt $BACKUP_RETRIES ] && [ "$BACKUP_SUCCESS" = false ]; do
        BACKUP_COUNT=$((BACKUP_COUNT + 1))
        echo "Attempting base backup (Attempt $BACKUP_COUNT/$BACKUP_RETRIES)..."
        
        if PGPASSWORD=$REPLICATION_PASSWORD pg_basebackup \
            -h $PRIMARY_HOST \
            -p $PRIMARY_PORT \
            -U $REPLICATION_USER \
            -D /var/lib/postgresql/data \
            -Fp \
            -Xs \
            -P \
            -R; then
            BACKUP_SUCCESS=true
            echo "Base backup completed successfully"
        else
            echo "Base backup failed, retrying in 5 seconds..."
            sleep 5
        fi
    done

    if [ "$BACKUP_SUCCESS" = false ]; then
        echo "ERROR: Failed to create base backup after $BACKUP_RETRIES attempts"
        exit 1
    fi

    echo "Creating standby.signal..."
    touch /var/lib/postgresql/data/standby.signal

    # Configure replica to connect to primary with unique slot name
    cat > /var/lib/postgresql/data/postgresql.auto.conf <<EOF
primary_conninfo = 'host=$PRIMARY_HOST port=$PRIMARY_PORT user=$REPLICATION_USER password=$REPLICATION_PASSWORD application_name=$(hostname)'
hot_standby = on
primary_slot_name = '$REPLICA_SLOT_NAME'
max_connections = 200
shared_buffers = 256MB
EOF

    # Set proper ownership and permissions
    chown -R postgres:postgres /var/lib/postgresql/data
    chmod 700 /var/lib/postgresql/data
    
    echo "Replica setup completed successfully"
fi

# Start PostgreSQL as postgres user
echo "Starting PostgreSQL server..."
exec gosu postgres postgres