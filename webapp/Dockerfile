# syntax=docker/dockerfile:1

FROM python:3.11.3-slim-bullseye

COPY start.sh /usr/local/bin/start.sh
RUN chmod ugo+x /usr/local/bin/start.sh

WORKDIR /vault-agent

COPY vault-agent/vault-agent.hcl .
COPY vault-agent/config.tmpl .

WORKDIR /webapp

ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0

COPY app/requirements.txt .

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y gcc default-libmysqlclient-dev pkg-config gpg wget lsb-release
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
RUN apt-get update && apt-get install -y vault
RUN rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip \
    && pip install -r requirements.txt

EXPOSE 5000

COPY app/*.py .
COPY app/templates templates

CMD ["/usr/local/bin/start.sh"]

