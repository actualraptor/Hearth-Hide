# Publishing on Wago Addons

Each addon is its own Wago project, so people can install just the one they want.
Everything to paste is in the three files next to this one.

## For each addon

1. On [addons.wago.io](https://addons.wago.io) open the developer dashboard and **create a new project**.
2. Fill in from the matching file (`hunters-journal.md`, `well-met.md`, `mannerisms.md`):
   - **Name** and **summary**
   - **Game:** World of Warcraft: Forever
   - **Categories** (the suggestions fit Wago's usual list; pick the closest)
   - **Description:** copy the block under "Description", it's Markdown
   - **Logo:** `.github/assets/logo-*.png` (512×512)
   - **Screenshots:** the files listed, from `.github/assets/`
3. **Upload a version:** the zip from `downloads/` (e.g. `WellMet.zip`), label it with the version, stability *Stable*, game version Forever (interface 16001), and paste the changelog.
4. Copy the 8-character **project ID** under the addon's name and send it to Claude. It goes into the addon's `.toc` as `## X-Wago-ID:` so the Wago app can keep people updated, and it lets future updates be automated.

## Later: automatic updates (optional)

With the three project IDs and a Wago API key saved as the repository secret `WAGO_API_TOKEN`
(GitHub › Settings › Secrets and variables › Actions), a small GitHub workflow can upload new
versions to Wago by itself whenever a version tag is pushed.
