#!/usr/bin/env sh

# Source: https://github.com/ahmetkaftan/docker-vault

set -ex

unseal () {
    vault operator unseal $(grep 'Key 1:' /vault/file/keys | awk '{print $NF}')
    vault operator unseal $(grep 'Key 2:' /vault/file/keys | awk '{print $NF}')
    vault operator unseal $(grep 'Key 3:' /vault/file/keys | awk '{print $NF}')
}

init () {
    vault operator init > /vault/file/keys
}

log_in () {
    export ROOT_TOKEN=$(grep 'Initial Root Token:' /vault/file/keys | awk '{print $NF}')
    vault login $ROOT_TOKEN
}

wait_mysql() {
    echo "Waiting MySQL to be ready..."
    while ! nc -z database 3306; do   
        sleep 3
    done
    echo "MySQL is ready!"
}

# Source: https://developer.hashicorp.com/vault/docs/secrets/databases/mysql-maria#setup
configure_mysql () {
    vault secrets enable database
    vault write database/config/mysql-database \
        plugin_name=mysql-database-plugin \
        connection_url="{{username}}:{{password}}@tcp(database:3306)/" \
        allowed_roles="mysql-role" \
        username="root" \
        password=$MYSQL_INITIAL_ROOT_PASSWORD
    vault write database/roles/mysql-role \
        db_name=mysql-database \
        creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}'; GRANT SELECT, INSERT ON \`notes_webapp\`.* TO '{{name}}'@'%';" \
        default_ttl="3m" \
        max_ttl="5m"
    # Source: https://developer.hashicorp.com/vault/tutorials/db-credentials/database-root-rotation#step-3-rotate-the-root-credentials
    # TODO: IT DOESN'T WORK!
    vault write -force database/rotate-root/mysql-database
}

# Sources:
#   - https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-policies#associate-policies-to-auth-methods
#   - https://developer.hashicorp.com/vault/docs/agent-and-proxy/autoauth
#   - https://developer.hashicorp.com/vault/docs/agent-and-proxy/autoauth/methods/approle
#       (Why 'token_num_uses=0'? See the callout here: https://developer.hashicorp.com/vault/docs/agent-and-proxy/autoauth#configuration-method)
configure_webapp_vault_client() {
    vault policy write read-mysql-creds-policy /vault-policies/read-mysql-creds-policy.hcl
    vault auth enable approle
    vault write auth/approle/role/webapp-role \
        secret_id_ttl=3m \
        secret_id_num_uses=5 \
        token_ttl=3m \
        token_max_ttl=5m \
        token_num_uses=0 \
        token_policies=read-mysql-creds-policy
    vault read -field=role_id auth/approle/role/webapp-role/role-id > /vault/file/agent/role_id
    while true; do
        vault write -f -field=secret_id auth/approle/role/webapp-role/secret-id > /vault/file/agent/secret_id
        sleep 180
    done
}

if [ -s /vault/file/keys ]; then
    unseal
else
    init
    unseal
    log_in
    wait_mysql
    configure_mysql
    configure_webapp_vault_client
fi

vault status > /vault/file/status

