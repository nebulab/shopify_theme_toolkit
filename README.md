# ShopifyThemeToolkit

Shopify Theme Toolkit is a comprehensive solution for modern Shopify theme development. It enables you to quickly scaffold new themes or enhance existing ones with automated workflows, version management, and best practices. The toolkit configures Ruby and pnpm versioning, integrates the Shopify CLI and Foreman for local development, and adds ready-to-use GitHub Actions for theme checking, performance audits, and PR previews. Optional Tailwind CSS setup is included, with automatic build integration and theme.liquid injection. Ideal for individuals and teams, this toolkit ensures your themes are production-ready, CI/CD-friendly, and easy to maintain.

## Requirements

To use Shopify Theme Toolkit, you need to have the following tools installed on your system:

- curl or wget (to download the installation script and workflow files)
- Node.js and npx (to create a new Shopify theme if not already existing)
- mise or asdf (for version management)

## Installation

```sh
curl https://raw.githubusercontent.com/nebulab/shopify_theme_toolkit/refs/heads/main/install.sh | sh
```

### Options

You can pass the following environment variables to customize the installation:

- `RUBY_VERSION`: Specify a Ruby version (default: latest)
- `PNPM_VERSION`: Specify a pnpm version (default: latest)
- `USE_CURRENT_DIR`: Set to `true` to skip theme scaffolding and install in the current directory.

Examples:

```sh
curl https://raw.githubusercontent.com/nebulab/shopify_theme_toolkit/refs/heads/main/install.sh | RUBY_VERSION=3.1.2 bash -s
```

```sh
curl https://raw.githubusercontent.com/nebulab/shopify_theme_toolkit/refs/heads/main/install.sh | USE_CURRENT_DIR=true bash -s
```

## Features

- Theme management: Quickly create a new Shopify theme using the default Shopify CLI command, or use any existing theme directory.
- Tools file: A pre-configured tools file to manage your development dependencies using mise or asdf.
- Shopify CLI integration: Seamless integration with the Shopify CLI for theme development and deployment.
- GitHub Actions workflows for automated theme checking and testing:
  - Theme Check Workflow: Automatically runs Shopify's Theme Check on every push to ensure code quality and adherence to best practices (https://github.com/marketplace/actions/run-theme-check-on-shopify-theme).
  - Lighthouse CI Workflow: Runs Lighthouse audits on your theme to ensure optimal performance and accessibility (https://github.com/marketplace/actions/run-lighthouse-ci-on-shopify-theme).
  - PR Theme Management Workflow: Manages theme previews for pull requests, allowing for easy testing and review of changes (https://github.com/marketplace/actions/shopify-pr-theme-preview).
- Foreman default setup: A default Procfile for running the Shopify theme dev server using bin/dev command.
- Optional Tailwind CSS integration: Ask the user if they want to install Tailwind CSS if not detected in your package.json. Then, the installation script automatically configures the build process and includes the generated CSS in your theme layout.

## GitHub Actions Requirements

### Workflow Permissions
To ensure the GitHub Actions workflows work correctly, please give read and write permissions to Actions in your repository settings
1. Navigate to your repository on GitHub.
2. Click on the "Settings" tab.
3. In the left sidebar, click on "Actions" and then "General".
4. Under "Workflow permissions", select "Read and write permissions".
5. Click "Save" to apply the changes.

### Required Secrets
The following secrets need to be added to your GitHub repository for the workflows to operate correctly:
- `SHOP_STORE`: Your store URL (e.g., your-store.myshopify.com)
- `SHOP_ACCESS_TOKEN`: Your Shopify Admin API access token with appropriate permissions. Follow https://github.com/marketplace/actions/run-lighthouse-ci-on-shopify-theme#authentication
- `LHCI_GITHUB_APP_TOKEN`: [Lighthouse GitHub app](https://github.com/apps/lighthouse-ci) token. Install the app on your repository to generate the token.
- `SHOPIFY_CLI_THEME_TOKEN`: Your Shopify CLI theme token. Follow https://shopify.dev/docs/storefronts/themes/tools/cli/ci-cd#step-1-get-a-theme-access-password-for-the-store

