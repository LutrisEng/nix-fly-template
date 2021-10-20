# nix-fly-template

This is a barebones template to build an application with Nix and deploy it on Fly.io.

## How to use

 1. Use this template to create a repository for your app
 2. Launch a Fly app for each environment you want (prod, staging, etc.)
 3. Add your Fly apps' names in `fly.nix`, and configure `.github/workflows/fly.yml` to deploy to your apps
 4. Add a `FLY_API_TOKEN` secret to your GitHub repo containing a Fly API token
 5. Modify `app.nix` and `flake.nix` to build your app and Docker container however you want

GitHub Actions will deploy to staging then production on every push to the main branch.