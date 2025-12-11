#!/bin/bash
set -e

echo "Setting up replication user and configuration..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create replication user
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'replicator') THEN
            CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'replicator_password';
        END IF;
    END
    \$\$;

    -- Grant necessary permissions
    GRANT CONNECT ON DATABASE "$POSTGRES_DB" TO replicator;
    
    -- Create replication slot for each replica
    SELECT pg_create_physical_replication_slot('replica1_slot');
    SELECT pg_create_physical_replication_slot('replica2_slot');
EOSQL

# Update pg_hba.conf to allow replication connections
cat >> "$PGDATA/pg_hba.conf" <<EOF

# Replication connections from Docker Swarm overlay network (allow without SSL)
host replication replicator 0.0.0.0/0 trust
host all all 0.0.0.0/0 trust

# Allow connections from pgpool
host all all 10.0.0.0/8 trust
host all all 172.16.0.0/12 trust
host all all 192.168.0.0/16 trust
EOF

# Reload PostgreSQL configuration
pg_ctl reload -D "$PGDATA"

echo "Replication user and configuration completed successfully"