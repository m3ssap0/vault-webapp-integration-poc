# syntax=docker/dockerfile:1

FROM hashicorp/vault:1.17

COPY read-mysql-creds-policy.hcl /vault-policies/read-mysql-creds-policy.hcl

COPY vault-init.sh /usr/local/bin/vault-init.sh
RUN chmod ugo+x /usr/local/bin/vault-init.sh

CMD ["/usr/local/bin/vault-init.sh"]

