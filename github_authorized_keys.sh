#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Inspired by https://blog.tedivm.com/guides/2021/11/openssh-pull-keys-from-github-authorizedkeyscommand/

TARGET_USER=${1}
# Explicit "allow" list in case GitHub users overlap with system users
ALLOWED_USERS="nemchik"
USER_DIR=$(eval echo ~"${TARGET_USER}")
KEY_DIR=${USER_DIR}/.ssh
KEY_FILE=${KEY_DIR}/authorized_keys
KEY_URL="https://github.com/${TARGET_USER}.keys"

if [[ -z ${TARGET_USER} ]]; then
    echo >&2 "Username required."
    exit 1
fi

if [[ ! -d ${USER_DIR} ]]; then
    echo >&2 "User directory does not exist."
    exit 1
fi

if [[ ! " ${ALLOWED_USERS} " =~ .*\ ${TARGET_USER}\ .* ]]; then
    echo >&2 "User not in allowed list."
    exit 1
fi

TMP_AUTHORIZED_KEYS=$(mktemp)
HTTP_STATUS=$(curl -m 5 -s -o "${TMP_AUTHORIZED_KEYS}" -w "%{http_code}" "${KEY_URL}") || true
PUBLIC_KEYS=$(cat "${TMP_AUTHORIZED_KEYS}")
rm "${TMP_AUTHORIZED_KEYS}"

if [[ "${HTTP_STATUS}" != "200" ]]; then
    echo >&2 "Pulling keys from GitHub failed with status code ${HTTP_STATUS}"
    exit 1
else
    mkdir -p "${KEY_DIR}"
    touch "${KEY_FILE}"
    for PUBLIC_KEY in ${PUBLIC_KEYS}; do
        if ! grep -q "${PUBLIC_KEY}" "${KEY_FILE}"; then
            echo "${PUBLIC_KEY}" >>"${KEY_FILE}"
        fi
    done
    cat "${KEY_FILE}"
fi
