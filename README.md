# Apache Airflow in Hetzner Cloud

Single machine deployment of [Apache Airflow](https://airflow.apache.org) in Hetzner Cloud using [Packer](https://www.packer.io/downloads) and [OpenTofu](<https://opentofu.org/downloads>)

## What's Included

- Apache Airflow with Celery Executor.
- PostgreSQL as the metadata database.
- Redis as the Celery message broker.
- Systemd services to manage Airflow components [^1] (Scheduler, Webserver, Celery Worker).
- User `admin` with password `admin` to log in the web interface.

## Hetzner Server Configuration

`cx22` server with the below specs:

- **CPU**: `2`
- **Memory**: `4GB`
- **Disk**: `40GB`

For the server price check [Hetzner Cloud documentation](https://www.hetzner.com/cloud).

## Prerequisites

- [Packer](https://www.packer.io/downloads)
- [OpenTofu](<https://opentofu.org/downloads>)
- An active [Hetzner Cloud](https://www.hetzner.com/cloud) account.
- A Hetzner Cloud API Token. You can create one from your Hetzner Cloud Console under `Security > API tokens`.

## Setup

Summary of the steps:

1. Create `.env` file with the environment variables required by Packer and OpenTofu.
2. Create SSH Key in Hetzner. This key will be used by Packer provisioners to create the snapshot.
3. Build Apache Airflow snapshot with Packer. The created snapshot will be available in Hetzner Cloud Console under `Servers > Images`.
4. Use the latest image built in step 2 to create a new server using OpenTofu.

### Step 1: Create `.env` File

```bash
cat <<-EOF > .env
PKR_VAR_hcloud_token=<your_hetzner_api_token>
PKR_VAR_db_password=<airflow_db_user_password>
TF_VAR_hcloud_token=<your_hetzner_api_token>
TF_VAR_passphrase=<opentofu_state_encryption_passphrase>
EOF 
```

> [!IMPORTANT]
> Store the API token and passphrase in a safe place once the server is up and running, and clean up the `.env` file.

### Step 2: Create the SSH Key

Create SSH key pairs [^2]. Save the public key in a file named `id_rsa.pub`, and add the private key to your SSH agent [^3]. After creating the SSH key, locally, run the following commands to create it in Hetzner Cloud:

```shell
cp id_rsa.pub ssh-key/ && cd ssh-key
tofu init
source ../.env && tofu apply
```

### Step 3: Build Apache Airflow Snapshot with Packer

```shell
cd ../server-image
packer init .
source ../.env && packer build
```

### Step 4: Create the Server with OpenTofu

```shell
cd ../server
tofu init
source ../.env && tofu apply
```

## Accessing Airflow UI

Once the `tofu apply` command is complete, it will output the URL for your Airflow web interface.

- **URL**: `http://<your-server-ip>:8080`
- **Username**: `admin`
- **Password**: `admin`

> [!CAUTION]
> Remember to change the password of the `admin` user.

## Cleaning Up

To avoid incurring further costs, you should destroy the created resources when you are finished.

1. **Destroy the Server:**

    ```bash
    cd server
    source ../.env && tofu destroy --auto-approve
    ```

2. **Destroy the SSH Key:**

    ```bash
    cd ../ssh-key
    souce ../.env && tofu destroy --auto-approve
    ```

3. **Delete the Snapshot:**
    - Go to your Hetzner Cloud Console.
    - Navigate to `Images`.
    - Find the snapshot named `Apache Airflow - ...` and delete it.

[^1]: <https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/overview.html>
[^2]: <https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key>
[^3]: <https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#adding-your-ssh-key-to-the-ssh-agent>

