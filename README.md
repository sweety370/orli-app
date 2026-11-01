# ORLI — Organize Life

ORLI is a Flutter personal organizer with two Android editions:

- **ORLI Lite**: home dashboard, planner/tasks and notes.
- **ORLI Pro**: everything in Lite plus money overview and health/routine section.

## Build APKs on GitHub

1. Create a GitHub repository named `ORLI`.
2. Upload all files and folders from this project to the repository root.
3. Open **Actions**. The workflow builds Lite and Pro APKs on every push to `main`/`master`, and can also be started manually with **Run workflow**.
4. Open the completed workflow run and download:
   - `ORLI-lite-APK`
   - `ORLI-pro-APK`

The APKs use different application IDs, so both editions can be installed side by side.

## Current prototype scope

- Tasks/planner entries, notes and money totals are saved locally with SharedPreferences.
- The medicine/health area is an organizer placeholder. This prototype does not yet schedule Android notifications or provide medical instructions.
- No account or cloud sync is included.
