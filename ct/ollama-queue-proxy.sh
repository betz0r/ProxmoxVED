#!/usr/bin/env bash
# WHILE DEVELOPING/TESTING source from ProxmoxVED (or your own fork).
# Before opening the PR against ProxmoxVE, switch this URL to the community-scripts repo.
source <(curl -fsSL https://raw.githubusercontent.com/betz0r/ProxmoxVED/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: betz0r
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TadMSTR/ollama-queue-proxy

APP="Ollama-Queue-Proxy"
var_tags="${var_tags:-ai;proxy}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/ollama-queue-proxy ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if fetch_and_deploy_gh_release "ollama-queue-proxy" "TadMSTR/ollama-queue-proxy" "tarball"; then
    msg_info "Updating ${APP}"
    $STD uv pip install --python /opt/ollama-queue-proxy/.venv/bin/python /opt/ollama-queue-proxy
    systemctl restart ollama-queue-proxy
    msg_ok "Updated ${APP}"
  else
    msg_ok "Already up to date"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Edit the Ollama host + API key in:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}/opt/ollama-queue-proxy/config.yml${CL}"
echo -e "${INFO}${YW}Then point your Ollama clients at:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:11435${CL}"
