# Publishing this project to GitHub (Person 1)

The archive contains the complete project files, but a **remote GitHub repository is not created automatically**. Publish it under your own GitHub account using one of the two methods below.

## Option A — GitHub CLI (recommended, PowerShell)

1. Extract the project ZIP into your preferred working folder.
2. Install the GitHub CLI if needed:

   ```powershell
   winget install --id GitHub.cli -e
   ```

3. Open a **new** PowerShell terminal and navigate to the extracted `tls-security-project` directory.
4. Authenticate and create the repository:

   ```powershell
   gh auth login
   git init -b main
   git add .
   git status --short
   git commit -m "Initial TLS lab infrastructure"
   gh repo create tls-security-project --private --source . --remote origin --push
   ```

If `git commit` asks for an author, configure **your own** Git author identity using `git config user.name "..."` and `git config user.email "..."` then retry the commit. `gh auth login` opens a guided GitHub sign-in flow.

GitHub repository names are not globally unique; you can choose a different name. Use `--public` instead of `--private` only if your group wants to publish the lab publicly. Do not publish private keys or generated CA files, even in a private repository.

## Option B — GitHub website

1. On GitHub create an **empty** repository (do not generate a README/.gitignore because the project already includes them).
2. In the extracted directory:

   ```powershell
   git init -b main
   git add .
   git commit -m "Initial TLS lab infrastructure"
   git remote add origin https://github.com/YOUR_ACCOUNT/tls-security-project.git
   git push -u origin main
   ```

3. Authenticate when prompted. Replace `YOUR_ACCOUNT` with your actual account name.

## Invite teammates

In GitHub, open your repository and use **Settings → Collaborators / Access → Add people** (labels may vary by organization). Give Persons 2 and 3 write access so they can add experiment notes and report material.

## Suggested branches

- `main`: known-working testbed
- `audit/person2`: scanner procedures and results documentation
- `downgrade/person3`: downgrade and mitmproxy procedure

Members create a branch, make changes, and open a pull request to merge into `main`. A GitHub Actions workflow (`.github/workflows/testbed.yml`) attempts smoke tests on pushes and pull requests using a GitHub-hosted Linux runner. Its first run is an additional **real Docker validation** of the environment; if it fails, review the logs and fix the configuration before your team relies on it.

## Basic Git commands after publishing

```powershell
git status
git add .
git commit -m "Describe the change"
git push
```

**Important:** The archive's `certs/` and `results/` directories are excluded by `.gitignore`, except for their `.gitkeep` placeholders. Check `git status` before committing and never override these protections to upload generated private keys.
