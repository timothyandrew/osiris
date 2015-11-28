#!/usr/bin/env bash

set -e

SWITCH="\033["
NORMAL="${SWITCH}0m"
YELLOW="${SWITCH}1;33m"

execute() {
    local command=$1
    echo
    echo -e " ====> Running ${YELLOW} $command ${NORMAL}"
    echo
    eval $command
    return $?
}

execute "cd /apps/osiris; bundle exec foreman run rake thumbnails:update"
execute "curl https://nosnch.in/29d11f8d05"
