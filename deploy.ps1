# =============================================================
#  Nath Digital Archives — GitHub Pages Deploy Script
#  PowerShell 7  |  Run from the project folder
# =============================================================

param(
    [string]$Username = "",
    [string]$Repo     = "nath-archives",
    [switch]$InitOnly,
    [switch]$Update
)

# ── Helpers ────────────────────────────────────────────────
function Write-Step { param($msg) Write-Host "`n► $msg" -ForegroundColor Cyan }
function Write-OK   { param($msg) Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "  ⚠ $msg" -ForegroundColor Yellow }
function Write-Err  { param($msg) Write-Host "  ✗ $msg" -ForegroundColor Red }

# ── Banner ─────────────────────────────────────────────────
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor DarkYellow
Write-Host "  ║     ॐ  NATH DIGITAL ARCHIVES             ║" -ForegroundColor DarkYellow
Write-Host "  ║     GitHub Pages Deployment Script       ║" -ForegroundColor DarkYellow
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor DarkYellow
Write-Host ""

# ── Get username if not provided ────────────────────────────
if (-not $Username) {
    $Username = Read-Host "Enter your GitHub username"
}
if (-not $Username) { Write-Err "Username required."; exit 1 }

$RepoUrl = "https://github.com/$Username/$Repo.git"
$PagesUrl = "https://$Username.github.io/$Repo/"

# ── Check prerequisites ─────────────────────────────────────
Write-Step "Checking prerequisites…"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Err "Git not found. Install from: https://git-scm.com/"
    exit 1
}
Write-OK "Git found: $(git --version)"

$hasGhCli = Get-Command gh -ErrorAction SilentlyContinue
if ($hasGhCli) {
    Write-OK "GitHub CLI found: $(gh --version | Select-Object -First 1)"
} else {
    Write-Warn "GitHub CLI not found (optional). Install: winget install GitHub.cli"
}

# ── INIT — First-time setup ─────────────────────────────────
if (-not $Update) {
    Write-Step "Initializing Git repository…"

    if (Test-Path ".git") {
        Write-Warn ".git folder already exists. Skipping git init."
    } else {
        git init
        Write-OK "Git initialized"
    }

    # Create .gitignore
    @"
*.DS_Store
Thumbs.db
.env
*.log
node_modules/
"@ | Set-Content ".gitignore"
    Write-OK "Created .gitignore"

    # Create README
    @"
# ॐ Nath Digital Archives

Sacred texts and teachings of the Nath Sampradaya, rooted in the immortal Mahayogi Gorakhnath.

## Live Archive
$PagesUrl

## Structure
- ``index.html`` — Public reader portal
- ``admin/`` — Admin upload panel
- ``books/`` — Uploaded PDFs and texts
- ``covers/`` — Book cover images
- ``data/books.json`` — Book catalog

## Admin Login
Default credentials (change before deploy!):
- Username: ``keeper``
- Password: ``gorakh108``

## Alakh Niranjan 🔥
"@ | Set-Content "README.md"
    Write-OK "Created README.md"

    Write-Step "Staging files…"
    git add .
    git status --short

    Write-Step "Creating initial commit…"
    git commit -m "Initial commit: Nath Digital Archives ॐ"
    git branch -M main
    Write-OK "Commit created"

    Write-Step "Connecting to GitHub remote…"
    # Check if remote exists
    $remotes = git remote
    if ($remotes -contains "origin") {
        Write-Warn "Remote 'origin' already set. Updating URL."
        git remote set-url origin $RepoUrl
    } else {
        git remote add origin $RepoUrl
    }
    Write-OK "Remote set to: $RepoUrl"

    Write-Step "Pushing to GitHub…"
    Write-Host "  (You may be prompted for GitHub credentials)" -ForegroundColor Gray
    git push -u origin main

    if ($LASTEXITCODE -ne 0) {
        Write-Err "Push failed. Make sure:"
        Write-Host "  1. Repository '$Repo' exists on GitHub" -ForegroundColor Gray
        Write-Host "  2. You have write access" -ForegroundColor Gray
        Write-Host "  3. Run: gh auth login   (if using GitHub CLI)" -ForegroundColor Gray
        exit 1
    }
    Write-OK "Pushed to GitHub!"

    # Enable GitHub Pages via CLI
    if ($hasGhCli) {
        Write-Step "Enabling GitHub Pages…"
        try {
            gh api "repos/$Username/$Repo/pages" `
                --method POST `
                --field 'source={"branch":"main","path":"/"}' `
                --silent 2>$null
            Write-OK "GitHub Pages enabled!"
        } catch {
            Write-Warn "Could not auto-enable Pages. Do it manually:"
            Write-Host "  GitHub → $Repo → Settings → Pages → Source: main / (root)" -ForegroundColor Gray
        }
    } else {
        Write-Warn "Enable GitHub Pages manually:"
        Write-Host "  GitHub → $Repo → Settings → Pages → Source: main / (root)" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "  ═══════════════════════════════════════════" -ForegroundColor DarkYellow
    Write-Host "  ✓  DEPLOYMENT COMPLETE!" -ForegroundColor Green
    Write-Host "  ═══════════════════════════════════════════" -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "  🌐 Public Archive:  $PagesUrl" -ForegroundColor Cyan
    Write-Host "  🔐 Admin Panel:     $($PagesUrl)admin/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Note: GitHub Pages may take 1-3 minutes to go live." -ForegroundColor Gray
    Write-Host "  Default admin login: keeper / gorakh108" -ForegroundColor Gray
    Write-Host "  Change credentials in admin/index.html before deploying!" -ForegroundColor Yellow
    Write-Host ""
}

# ── UPDATE — Push changes ───────────────────────────────────
if ($Update) {
    Write-Step "Pushing updates to GitHub…"
    git add .
    $msg = Read-Host "Commit message (or press Enter for default)"
    if (-not $msg) { $msg = "Update archive $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }
    git commit -m $msg
    git push origin main

    if ($LASTEXITCODE -eq 0) {
        Write-OK "Updates pushed! Changes live in ~1 minute."
        Write-Host "  🌐 $PagesUrl" -ForegroundColor Cyan
    } else {
        Write-Err "Push failed."
    }
}
