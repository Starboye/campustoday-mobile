# Push to GitHub (one-time setup)

Git is ready locally. GitHub CLI needs login **once** on this PC.

## Step 1 — Log in to GitHub CLI

Open PowerShell and run:

```powershell
gh auth login
```

Choose:
- GitHub.com
- HTTPS
- Login with browser (easiest)

## Step 2 — Create repo and push

```powershell
cd C:\xampp\htdocs\campustoday-mobile
gh repo create Starboye/campustoday-mobile --public --source=. --remote=origin --description "CampusToday mobile: Laravel API + Flutter app" --push
```

If the repo already exists on GitHub:

```powershell
cd C:\xampp\htdocs\campustoday-mobile
git remote add origin https://github.com/Starboye/campustoday-mobile.git
git push -u origin main
```

## Repo URL (after push)

https://github.com/Starboye/campustoday-mobile

## Contents

| Folder | Description |
|--------|-------------|
| `api/` | Laravel JSON API |
| `app/` | Flutter app (Android/iOS/Web) |

Secrets **not** included (`.env` is gitignored). Run `composer install` in `api/` after clone.
