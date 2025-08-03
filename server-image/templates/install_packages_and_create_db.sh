apt-get update
apt-get upgrade -y
apt-get install -y python3-pip python3-venv libpq-dev gcc postgresql postgresql-contrib redis-server

# Start and enable PostgreSQL and Redis
systemctl start postgresql
systemctl enable postgresql
systemctl start redis-server
systemctl enable redis-server

# Create airflow user and set up virtual environment
sudo useradd -m -d ${AIRFLOW_USER_HOME} ${AIRFLOW_OS_USER} || true

# Setup PostgreSQL user and database for Airflow
sudo -u postgres psql -c "CREATE USER ${DB_USERNAME} WITH PASSWORD '${DB_PASSWORD}' "
sudo -u postgres psql -c "CREATE DATABASE airflowdb OWNER ${DB_USERNAME}"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE airflowdb TO ${DB_USERNAME}"
sudo -u postgres psql -c "GRANT ALL ON SCHEMA public TO ${DB_USERNAME}"

# Setup python virtual environment for airflow user
sudo -i -u ${AIRFLOW_OS_USER} bash -c "python3 -m venv ${AIRFLOW_USER_HOME}/airflow_venv"

PYTHON_VERSION="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

# Upgrade pip and install Airflow with celery, postgres, and redis extras
sudo -i -u ${AIRFLOW_OS_USER} bash -c "${AIRFLOW_USER_HOME}/airflow_venv/bin/pip install --upgrade pip"
sudo -i -u ${AIRFLOW_OS_USER} bash -c "${AIRFLOW_USER_HOME}/airflow_venv/bin/pip install \"apache-airflow[fab,celery,postgres,redis]==${AIRFLOW_VERSION}\" --constraint ${CONSTRAINT_URL}"

# Prepare AIRFLOW_HOME and directories
sudo -i -u ${AIRFLOW_OS_USER} bash -c "mkdir -p ${AIRFLOW_USER_HOME}/{dags, logs, plugins}"
