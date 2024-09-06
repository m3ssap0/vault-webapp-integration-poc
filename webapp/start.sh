#!/usr/bin/env sh

# Source: https://developer.hashicorp.com/vault/tutorials/vault-agent/agent-quick-start#start-a-vault-agent
vault agent -config=/vault-agent/vault-agent.hcl &

flask run --debug

