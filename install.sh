#!/bin/sh
set -eu

YES_REPLIES=("y" "Y" "yes" "YES" "Yes")

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

# Ask for the Shopify theme name
info "Enter the name of a new or existing Shopify theme 💬:"
read THEME_NAME </dev/tty

# Check if the theme name is provided
if [ -z "$THEME_NAME" ]; then
  error "Error: Theme name cannot be empty."
fi

# Check if the theme directory already exists
if [ -d "$THEME_NAME" ]; then
  info "Theme folder $(blue "$THEME_NAME") already exists."

  # Ask the user if they want to use the existing folder
  info "Do you want to use the existing folder❔ ($(green "y")/$(red "N"))"
  read USE_EXISTING </dev/tty
  if [[ " ${YES_REPLIES[*]} " =~ " ${USE_EXISTING} " ]]; then
    info "Using existing folder $(blue "$THEME_NAME")."
  else
    info "$(red "Exiting without making changes.")"
    exit 0
  fi
else
  # Create the theme using Shopify CLI with the provided name
  info "Creating Shopify theme $(blue "$THEME_NAME")..."
  npx @shopify/cli@latest theme init "$THEME_NAME"
fi

# Navigate into the theme directory
cd "$THEME_NAME" || { error "Failed to enter directory '$THEME_NAME'"; }

info "$(green "Installation complete!") 🎉"
