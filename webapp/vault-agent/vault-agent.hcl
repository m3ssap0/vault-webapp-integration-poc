// Source: https://developer.hashicorp.com/vault/tutorials/vault-agent/agent-templates#start-vault-agent

pid_file = "./pidfile"

auto_auth {
  method {
    type = "approle"

    config = {
      role_id_file_path = "/vault-agent/ids/role_id"
      secret_id_file_path = "/vault-agent/ids/secret_id"
    }
  }

  sink "file" {
    config = {
      path = "/vault-agent/vault-token-via-agent"
    }
  }
}

vault {
  address = "http://vault-server:8200"
}

template {
  source      = "/vault-agent/config.tmpl"
  destination = "/webapp/config.ini"
}

