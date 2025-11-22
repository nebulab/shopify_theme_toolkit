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

# Required tools: curl or wget, Node.js, npx, mise or asdf

# Ensure Node.js and npx are installed
if ! command -v node >/dev/null 2>&1 || ! command -v npx >/dev/null 2>&1; then
  error "Error: Node.js and npx are required but not installed."
fi

# Get download tool (curl or wget)
download_tool=""
if command -v curl >/dev/null 2>&1; then
  download_tool="curl"
elif command -v wget >/dev/null 2>&1; then
  download_tool="wget"
else
  error "Error: Neither 'curl' nor 'wget' is installed. Please install one of them to download files."
fi

# Get tool versions manager (mise or asdf)
package_manager=""
if command -v mise >/dev/null 2>&1; then
  package_manager="mise"
elif command -v asdf >/dev/null 2>&1; then
  package_manager="asdf"
else
  error "Error: Neither 'mise' nor 'asdf' is installed. Please install one of them to manage tool versions."
fi

# If USE_CURRENT_DIR is set, use the current directory as theme name
if [ "${USE_CURRENT_DIR:-}" = "true" ]; then
  THEME_NAME=$(basename "$PWD")
  info "Using current directory as theme name: $(blue "$THEME_NAME")"
else
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
fi

# Create .tool-versions file if it doesn't exist
if [ ! -f .tool-versions ]; then
  info "Creating $(blue ".tool-versions") file..."
  touch .tool-versions
fi

# Add ruby version to .tool-versions if not already present
if ! grep -q "^ruby " .tool-versions; then
  info "Adding $(blue "Ruby") version to .tool-versions..."

  # Get ruby version from parameter or default to package manager latest command
  ruby_version="${RUBY_VERSION:-$(command $package_manager latest ruby)}"
  if [ -z "$ruby_version" ]; then
    error "Error: Unable to determine Ruby version."
  else
    info "Using Ruby version: $(blue "$ruby_version") 💎"
  fi

  echo "ruby $ruby_version" >> .tool-versions
else
  info "$(blue "Ruby") version already specified in .tool-versions."
fi

# Add pnpm version to .tool-versions if not already present
if ! grep -q "^pnpm " .tool-versions; then
  info "Adding $(blue "pnpm") version to .tool-versions..."

  # Get pnpm version from parameter or default to package manager latest command
  pnpm_version="${PNPM_VERSION:-$(command $package_manager latest pnpm)}"
  if [ -z "$pnpm_version" ]; then
    error "Error: Unable to determine pnpm version."
  else
    info "Using pnpm version: $(blue "$pnpm_version") 🧱"
  fi

  echo "pnpm $pnpm_version" >> .tool-versions
else
  info "$(blue "pnpm") version already specified in .tool-versions."
fi

# Install tools dependencies
info "Installing tool dependencies..."
$package_manager install

# Ensure tools are available in PATH by reshimming/reloading
if [ "$package_manager" = "mise" ]; then
  eval "$(mise env)"
elif [ "$package_manager" = "asdf" ]; then
  eval "$(asdf exec env)"
fi

# Add Shopify CLI to the project dependencies
info "Adding $(blue "Shopify CLI") 🛍️ to project dependencies..."
pnpm add -D @shopify/cli

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
  info "Creating $(blue ".env") file..."
  touch .env
fi

# Add .env to .gitignore if not already present
if [ -f .gitignore ] && ! grep -q "^.env$" .gitignore; then
  info "Adding $(blue ".env") to .gitignore..."
  echo ".env" >> .gitignore
fi

# Add SHOPIFY_FLAG_STORE environment variable to .env file
store_url="${STORE_URL:-'<your_store_name>'}"
if ! grep -q "^SHOPIFY_FLAG_STORE=" .env; then
  info "Adding $(blue "SHOPIFY_FLAG_STORE") environment variable to .env file..."
  echo "SHOPIFY_FLAG_STORE=$store_url" >> .env
fi

# Add foreman to the project dependencies
info "Adding $(blue "foreman") 👨‍💼 to project dependencies..."
if [ ! -f Gemfile ]; then
  bundle init
fi
if ! grep -q "foreman" Gemfile; then
  bundle add foreman
fi

# Add Github Actions workflows to the project
info "Adding $(blue "Github Actions") workflows ☑️ to the project..."
mkdir -p .github/workflows

# Download workflow files from the repository
base_url="https://raw.githubusercontent.com/nebulab/shopify_theme_toolkit/main/github-workflows"

workflows=(
  "lighthouse-ci.yml"
  "pr-theme.yml"
  "theme-check.yml"
)

for workflow in "${workflows[@]}"; do
  # Skip download if the workflow file already exists
  if [ -f ".github/workflows/$workflow" ]; then
    info "Workflow $(blue "$workflow") already exists. Skipping download."
    continue
  fi

  info "Downloading workflow: $(blue "$workflow")"
  if [ "$download_tool" = "curl" ]; then
    curl -fsSL "$base_url/$workflow" -o ".github/workflows/$workflow"
  elif [ "$download_tool" = "wget" ]; then
    wget -q "$base_url/$workflow" -O ".github/workflows/$workflow"
  fi
  
  if [ $? -eq 0 ]; then
    info "Successfully downloaded $(green "$workflow")"
  else
    error "Error: Failed to download $base_url/$workflow"
  fi
done

# Create theme-check configuration file if it doesn't exist
if [ ! -f ".theme-check.yml" ]; then
  info "Creating $(blue ".theme-check.yml") configuration file for theme-check..."
  pnpm shopify theme check --init
fi

# Create bin/dev script using foreman to run the Shopify theme dev server
info "Creating $(blue "bin/dev") script 💻 ..."
mkdir -p bin
if [ -f bin/dev ]; then
  info "$(blue "bin/dev") script already exists. Skipping creation."
else
  cat << 'EOF' > bin/dev
#!/bin/sh

exec foreman start -f Procfile.dev "$@"
EOF
  chmod +x bin/dev
  info "$(blue "bin/dev") script created successfully."
fi

# Create Procfile.dev for foreman
info "Creating $(blue "Procfile.dev") 📑 ..."
if [ -f Procfile.dev ]; then
  info "$(blue "Procfile.dev") already exists. Skipping creation."
else
  touch Procfile.dev
  echo "web: pnpm shopify theme dev" >> Procfile.dev
  info "$(blue "Procfile.dev") created successfully."
fi

# Check if Tailwind CSS is installed. If not, prompt the user to install it
if ! grep -q "tailwindcss" package.json; then
  # Ask the user if they want to install Tailwind CSS
  info "Do you want to install $(blue "Tailwind CSS") for styling 💇‍♀️? ($(green "y")/$(red "N"))"
  read INSTALL_TAILWIND </dev/tty
  if [[ " ${YES_REPLIES[*]} " =~ " ${INSTALL_TAILWIND} " ]]; then
    info "Installing $(blue "Tailwind CSS")..."
    pnpm add -D tailwindcss @tailwindcss/cli
    touch assets/tailwind.css
    echo '@import "tailwindcss";' >> assets/tailwind.css
  fi
fi

# Add Tailwind CSS build process to Procfile.dev
if grep -q "tailwindcss" package.json; then
  # Search for the Tailwind CSS input file in assets folder
  TAILWIND_INPUT_FILE=$(find assets -type f -name "*tailwind*.css" ! -name "*output*")
  if [ -n "$TAILWIND_INPUT_FILE" ]; then
    # Add Tailwind CSS build command to Procfile.dev if not already present
    if ! grep -q "tailwindcss" Procfile.dev; then
      echo "tailwind: pnpm tailwindcss -i ./$TAILWIND_INPUT_FILE -o ./assets/tailwind-output.css --watch" >> Procfile.dev
      info "Added $(blue "Tailwind CSS") build process to $(blue "Procfile.dev")."
    else
      info "$(blue "Tailwind CSS") build process already exists in $(blue "Procfile.dev")."
    fi
  else
    error "Error: Unable to find Tailwind CSS input file in assets folder. Please ensure you have a Tailwind CSS file with 'tailwind' in its name inside the assets directory."
  fi

  # Check the Tailwind CSS output file in theme.liquid layout
  if ! grep -q "tailwind-output.css" "layout/theme.liquid"; then
    info "Adding Tailwind CSS output file to layout/theme.liquid..."
    # Search for the first element containing "| asset_url | stylesheet_tag" and insert after it
    sed -i '' '1,/| asset_url | stylesheet_tag/ { /| asset_url | stylesheet_tag/ a\
    {{ "tailwind-output.css" | asset_url | stylesheet_tag }}
    }' layout/theme.liquid
  fi
fi

info "$(green "Installation complete!") 🎉"
if [ "${USE_CURRENT_DIR:-}" = "true" ]; then
  info "To start the development server run 👉: $(green "bin/dev")"
else
  info "To start the development server run 👉: $(green "cd $THEME_NAME && bin/dev")"
fi
