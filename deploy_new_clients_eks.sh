psql_user=$1
psql_user_password=$2

echo $psql_user
echo $psql_user_password

# Validating the existence of the needed parameters for the script

if [ -z "$psql_user" ]; then
    echo "ERROR: Missing Parameter, psql user is not defined"
    exit 1
fi
if [ -z "$psql_user_password" ]; then
    echo "ERROR: Missing Parameter, psql users password is not defined"
    exit 1
fi

# Creating PostgreSQL User


PGPASSWORD="$DB_MASTER_ENV_POSTGRES_PASSWORD" /usr/bin/psql -X -A --quiet --host $DB_PORT_5432_TCP_ADDR --port=5432 --username="$DB_MASTER_ENV_POSTGRES_USER" -t -c "CREATE USER \"$psql_user\" WITH PASSWORD '$psql_user_password'; "
error=$?; if [ $error -eq 0 ]; then echo "Postgres User created Succesfully"; else echo "ERROR: $error"; fi


PGPASSWORD="$DB_MASTER_ENV_POSTGRES_PASSWORD" /usr/bin/psql -X -A --quiet --host $DB_PORT_5432_TCP_ADDR --port=5432 --username="$DB_MASTER_ENV_POSTGRES_USER" -t -c "ALTER ROLE \"$psql_user\" WITH createdb; "
error=$?; if [ $error -eq 0 ]; then echo "Succesfully Altered Role with CREATEDB"; else echo "ERROR: $error"; fi
