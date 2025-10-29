#!/bin/sh
set -eu

# Logging helpers
info() {
  echo "$@" >&2
}

error() {
  echo "$(red "$@") ❌" >&2
  exit 1
}

blue() {
  printf "\033[34m%s\033[0m" "$*"
}

green() {
  printf "\033[32m%s\033[0m" "$*"
}

red() {
  printf "\033[31m%s\033[0m" "$*"
}

# Required tools: Node.js, npx

# Ensure Node.js and npx are installed
if ! command -v node >/dev/null 2>&1 || ! command -v npx >/dev/null 2>&1; then
  error "Error: Node.js and npx are required but not installed."
fi

info "$(green "Installation complete!") 🎉"
