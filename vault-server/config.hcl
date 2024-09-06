ui = true
api_addr = "http://127.0.0.1:8200"
default_lease_ttl = "168h"
max_lease_ttl = "720h"

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

storage "file" {
  path = "/vault/file"
}

