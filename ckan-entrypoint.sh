#!/bin/bash
set -e
CONFIG="${CKAN_CONFIG}/ckan.ini"
# URL for the primary database, in the format expected by sqlalchemy (required
# unless linked to a container called 'db')
: ${CKAN_SQLALCHEMY_URL:=}
# URL for solr (required unless linked to a container called 'solr')
: ${CKAN_SOLR_URL:=}
# URL for redis (required unless linked to a container called 'redis')
: ${CKAN_REDIS_URL:=}
# URL for datapusher (required unless linked to a container called 'datapusher')
: ${CKAN_DATAPUSHER_URL:=}

abort () {
  echo "$@" >&2
  exit 1
}

set_environment () {
  export CKAN_SITE_ID=${CKAN_SITE_ID}
  export CKAN_SITE_URL=${CKAN_SITE_URL}
  export CKAN_SQLALCHEMY_URL=${CKAN_SQLALCHEMY_URL}
  export CKAN_SOLR_URL=${CKAN_SOLR_URL}
  export CKAN_REDIS_URL=${CKAN_REDIS_URL}
  export CKAN_STORAGE_PATH=/var/lib/ckan
  export CKAN_DATAPUSHER_URL=${CKAN_DATAPUSHER_URL}
  export CKAN_DATASTORE_WRITE_URL=${CKAN_DATASTORE_WRITE_URL}
  export CKAN_DATASTORE_READ_URL=${CKAN_DATASTORE_READ_URL}
  export CKAN_SMTP_SERVER=${CKAN_SMTP_SERVER}
  export CKAN_SMTP_STARTTLS=${CKAN_SMTP_STARTTLS}
  export CKAN_SMTP_USER=${CKAN_SMTP_USER}
  export CKAN_SMTP_PASSWORD=${CKAN_SMTP_PASSWORD}
  export CKAN_SMTP_MAIL_FROM=${CKAN_SMTP_MAIL_FROM}
  export CKAN_MAX_UPLOAD_SIZE_MB=${CKAN_MAX_UPLOAD_SIZE_MB}
  export CKAN__PLUGINS="${CKAN__PLUGINS}"
  export DEFAULT_SYSADMIN_USER=${DEFAULT_SYSADMIN_USER}
  export DEFAULT_SYSADMIN_EMAIL=${DEFAULT_SYSADMIN_EMAIL}
  export DEFAULT_SYSADMIN_PASSWORD=${DEFAULT_SYSADMIN_PASSWORD}
}

write_config () {
  echo "Generating config at ${CONFIG}..."
  ckan generate config "$CONFIG"
  echo "${CKAN__PLUGINS}"
  ckan config-tool "$CONFIG" ckan.plugins="${CKAN__PLUGINS}"
}

# Wait for PostgreSQL
while ! pg_isready -h db -U ckan; do
  sleep 1;
done

# If we don't already have a config file, bootstrap
if [ ! -e "$CONFIG" ]; then
  write_config
fi

# Get or create CKAN_SQLALCHEMY_URL
if [ -z "$CKAN_SQLALCHEMY_URL" ]; then
  abort "ERROR: no CKAN_SQLALCHEMY_URL specified in docker-compose.yml"
fi

if [ -z "$CKAN_SOLR_URL" ]; then
    abort "ERROR: no CKAN_SOLR_URL specified in docker-compose.yml"
fi

if [ -z "$CKAN_REDIS_URL" ]; then
    abort "ERROR: no CKAN_REDIS_URL specified in docker-compose.yml"
fi

if [ -z "$CKAN_DATAPUSHER_URL" ]; then
    abort "ERROR: no CKAN_DATAPUSHER_URL specified in docker-compose.yml"
fi

set_environment
ckan --config "$CONFIG" db init
ckan --config /etc/ckan/ckan.ini datastore set-permissions | PGPASSWORD=${POSTGRES_PASSWORD} psql -h db -U ckan

echo "USER_EXISTS : $(ckan -c "$CONFIG" user list | grep "name=$DEFAULT_SYSADMIN_USER")"
if [ -z "$(ckan -c "$CONFIG" user list | grep "name=$DEFAULT_SYSADMIN_USER")" ]; then
  echo "Creating ADMIN_USER"
  ckan --config "$CONFIG" user add $DEFAULT_SYSADMIN_USER email=$DEFAULT_SYSADMIN_EMAIL password=$DEFAULT_SYSADMIN_PASSWORD
  ckan --config "$CONFIG" sysadmin add $DEFAULT_SYSADMIN_USER
else 
  echo "ADMIN_USER exists"
fi

exec "$@"
