psql_user=$1
psql_user_password=$2

# La contraseña no se imprime: todo lo que sale aquí queda en el log de Jenkins.
echo "Usuario PostgreSQL: $psql_user"

# Validating the existence of the needed parameters for the script

if [ -z "$psql_user" ]; then
    echo "ERROR: Missing Parameter, psql user is not defined"
    exit 1
fi
if [ -z "$psql_user_password" ]; then
    echo "ERROR: Missing Parameter, psql users password is not defined"
    exit 1
fi

run_sql() {
    PGPASSWORD="$DB_MASTER_ENV_POSTGRES_PASSWORD" /usr/bin/psql -X -A --quiet -v ON_ERROR_STOP=1 --host "$DB_PORT_5432_TCP_ADDR" --port=5432 --username="$DB_MASTER_ENV_POSTGRES_USER" --dbname=postgres -t -c "$1"
}

# Creating PostgreSQL User
# Si el usuario ya existe (el job se relanza), no se vuelve a crear ni se cambia su contraseña.

exists=$(run_sql "SELECT 1 FROM pg_roles WHERE rolname = '$psql_user';")
if [ "$exists" = "1" ]; then
    echo "Postgres User already exists, not created again"
else
    run_sql "CREATE USER \"$psql_user\" WITH PASSWORD '$psql_user_password';" || { echo "ERROR: could not create Postgres User"; exit 1; }
    echo "Postgres User created Succesfully"
fi

run_sql "ALTER ROLE \"$psql_user\" WITH createdb;" || { echo "ERROR: could not alter role with CREATEDB"; exit 1; }
echo "Succesfully Altered Role with CREATEDB"

# Límites de tiempo en el usuario (tarea 76807). Viven en PostgreSQL, así que acompañan
# al usuario en su base, en sus copias y en sus restauraciones. Los pases y el
# mantenimiento quedan exentos con PGOPTIONS en el entrypoint de la imagen.
for setting in \
    "statement_timeout = '30min'" \
    "lock_timeout = '30s'" \
    "client_connection_check_interval = '10s'" \
    "log_min_duration_statement = '30s'" \
    "log_lock_waits = on"
do
    run_sql "ALTER ROLE \"$psql_user\" SET $setting;" || { echo "ERROR: could not set $setting"; exit 1; }
done
echo "Succesfully set time limits on role"
