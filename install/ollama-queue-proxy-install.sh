#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: betz0r
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TadMSTR/ollama-queue-proxy

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y python3
msg_ok "Installed Dependencies"

# uv provides fast venv + pip; framework-managed
setup_uv

# Fetch source tarball to /opt/ollama-queue-proxy and record version
fetch_and_deploy_gh_release "ollama-queue-proxy" "TadMSTR/ollama-queue-proxy" "tarball"

msg_info "Installing Ollama Queue Proxy"
cd /opt/ollama-queue-proxy
$STD uv venv /opt/ollama-queue-proxy/.venv
$STD uv pip install --python /opt/ollama-queue-proxy/.venv/bin/python /opt/ollama-queue-proxy
msg_ok "Installed Ollama Queue Proxy"

msg_info "Creating Config"
API_KEY="sk-$(openssl rand -hex 24)"
cat <<EOF >/opt/ollama-queue-proxy/config.yml
proxy:
  host: "0.0.0.0"
  port: 11435
  max_concurrent: 2

ollama:
  hosts:
    # CHANGE THIS to the IP/URL of your Ollama host (native, VM, or other LXC)
    - url: "http://CHANGE_ME:11434"
      name: "primary"
  health_check_interval: 30
  request_timeout: 300

auth:
  enabled: true
  keys:
    - key: "${API_KEY}"
      client_id: "default"
      description: "Default client (auto-generated)"
      max_priority: high
      management: true

logging:
  level: "info"
  format: "text"
EOF
{
  echo "Ollama Queue Proxy"
  echo "API key: ${API_KEY}"
} >>~/ollama-queue-proxy.creds
msg_ok "Created Config"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/ollama-queue-proxy.service
[Unit]
Description=Ollama Queue Proxy
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Environment=OQP_CONFIG=/opt/ollama-queue-proxy/config.yml
WorkingDirectory=/opt/ollama-queue-proxy
ExecStart=/opt/ollama-queue-proxy/.venv/bin/ollama-queue-proxy
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now ollama-queue-proxy
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
