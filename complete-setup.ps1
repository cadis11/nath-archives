# =============================================================
#  Nath Digital Archives — COMPLETE SETUP
#  Run this in PowerShell 7 as Administrator
#  Does everything: files, git, GitHub Pages, custom domain
# =============================================================

$Folder   = "C:\Users\USER\Downloads\nath-archives"
$Username = "cadis11"
$Repo     = "nath-archives"
$Domain   = "nathdigitalarchive.com"

# ── Helpers ─────────────────────────────────────────────────
function Write-Step { param($m) Write-Host "`n► $m" -ForegroundColor Cyan }
function Write-OK   { param($m) Write-Host "  ✓ $m" -ForegroundColor Green }
function Write-Warn { param($m) Write-Host "  ⚠ $m" -ForegroundColor Yellow }
function Write-Err  { param($m) Write-Host "  ✗ $m" -ForegroundColor Red }

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor DarkYellow
Write-Host "  ║   ॐ  NATH DIGITAL ARCHIVES — FULL SETUP     ║" -ForegroundColor DarkYellow
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor DarkYellow
Write-Host ""

# ════════════════════════════════════════════════════════════
# STEP 1 — Go to folder
# ════════════════════════════════════════════════════════════
Write-Step "Step 1 — Navigating to project folder…"
if (-not (Test-Path $Folder)) {
    Write-Err "Folder not found: $Folder"
    Write-Host "  Make sure the nath-archives folder is in Downloads." -ForegroundColor Gray
    exit 1
}
Set-Location $Folder
Write-OK "In folder: $Folder"

# ════════════════════════════════════════════════════════════
# STEP 2 — Rename files if still have old names
# ════════════════════════════════════════════════════════════
Write-Step "Step 2 — Checking file names…"

if (Test-Path "index (1).html") {
    if (Test-Path "index.html") { Remove-Item "index.html" -Force }
    Rename-Item "index (1).html" "index.html"
    Write-OK "Renamed: 'index (1).html' → index.html"
} elseif (Test-Path "index.html") {
    Write-OK "index.html already in place"
} else {
    Write-Warn "index.html not found — skipping"
}

if (-not (Test-Path "admin")) {
    New-Item -ItemType Directory -Name "admin" | Out-Null
}

if (Test-Path "index (2).html") {
    if (Test-Path "admin\index.html") { Remove-Item "admin\index.html" -Force }
    Move-Item "index (2).html" "admin\index.html"
    Write-OK "Renamed: 'index (2).html' → admin\index.html"
} elseif (Test-Path "admin\index.html") {
    Write-OK "admin\index.html already in place"
} else {
    Write-Warn "admin\index.html not found — skipping"
}

# ════════════════════════════════════════════════════════════
# STEP 3 — Create folders and books.json
# ════════════════════════════════════════════════════════════
Write-Step "Step 3 — Creating required folders…"
@("books","covers","data") | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Name $_ | Out-Null
        Write-OK "Created: $_\"
    } else {
        Write-OK "Exists:  $_\"
    }
}
if (-not (Test-Path "data\books.json")) {
    "[]" | Set-Content "data\books.json" -Encoding UTF8
    Write-OK "Created: data\books.json"
}

# ════════════════════════════════════════════════════════════
# STEP 4 — Create CNAME for custom domain
# ════════════════════════════════════════════════════════════
Write-Step "Step 4 — Writing CNAME file for $Domain…"
$Domain | Set-Content "CNAME" -Encoding UTF8
Write-OK "CNAME file created → $Domain"

# ════════════════════════════════════════════════════════════
# STEP 5 — Create .gitignore and README
# ════════════════════════════════════════════════════════════
Write-Step "Step 5 — Creating .gitignore and README…"
@"
*.DS_Store
Thumbs.db
.env
*.log
node_modules/
"@ | Set-Content ".gitignore" -Encoding UTF8

@"
# OM Nath Digital Archives
Sacred texts of the Nath Sampradaya — rooted in Gorakhnath.
Live at: https://$Domain
"@ | Set-Content "README.md" -Encoding UTF8
Write-OK ".gitignore and README.md created"

# ════════════════════════════════════════════════════════════
# STEP 6 — Check Git
# ════════════════════════════════════════════════════════════
Write-Step "Step 6 — Checking Git…"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Err "Git is not installed!"
    Write-Host "  Install it: winget install Git.Git" -ForegroundColor Gray
    Write-Host "  Then close PowerShell, reopen, and run this script again." -ForegroundColor Gray
    exit 1
}
Write-OK "Git: $(git --version)"

# ════════════════════════════════════════════════════════════
# STEP 7 — Git init, commit, push
# ════════════════════════════════════════════════════════════
Write-Step "Step 7 — Setting up Git…"

if (-not (Test-Path ".git")) {
    git init
    Write-OK "Git initialized"
} else {
    Write-OK "Git already initialized"
}

git add .
git status --short

$hasChanges = git status --porcelain
if ($hasChanges) {
    git commit -m "Update: simplified admin + CNAME domain ($Domain)"
    Write-OK "Committed changes"
} else {
    Write-Warn "Nothing new to commit — already up to date"
}

git branch -M main

# Set remote
$remotes = git remote 2>$null
if ($remotes -contains "origin") {
    git remote set-url origin "https://github.com/$Username/$Repo.git"
    Write-OK "Remote origin updated"
} else {
    git remote add origin "https://github.com/$Username/$Repo.git"
    Write-OK "Remote origin added"
}

Write-Step "Step 8 — Pushing to GitHub…"
Write-Host "  (A login prompt may appear — use your GitHub token as the password)" -ForegroundColor Gray
Write-Host ""

git push -u origin main --force

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Err "Push failed. Try these fixes:"
    Write-Host ""
    Write-Host "  Option A — Login with GitHub CLI:" -ForegroundColor Yellow
    Write-Host "    winget install GitHub.cli" -ForegroundColor Gray
    Write-Host "    gh auth login" -ForegroundColor Gray
    Write-Host "    (then run this script again)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Option B — Use a token as password:" -ForegroundColor Yellow
    Write-Host "    1. Go to: https://github.com/settings/tokens/new" -ForegroundColor Gray
    Write-Host "    2. Check 'repo' scope → Generate → Copy token" -ForegroundColor Gray
    Write-Host "    3. Run: git push origin main --force" -ForegroundColor Gray
    Write-Host "    4. Username: cadis11  |  Password: paste your token" -ForegroundColor Gray
    exit 1
}

Write-OK "Pushed to GitHub!"

# ════════════════════════════════════════════════════════════
# STEP 9 — Enable GitHub Pages + custom domain via GitHub CLI
# ════════════════════════════════════════════════════════════
Write-Step "Step 9 — Enabling GitHub Pages with custom domain…"

$hasGH = Get-Command gh -ErrorAction SilentlyContinue
if ($hasGH) {
    # Enable Pages
    try {
        gh api "repos/$Username/$Repo/pages" `
            --method POST `
            --field 'source={"branch":"main","path":"/"}' 2>$null | Out-Null
        Write-OK "GitHub Pages enabled"
    } catch {
        Write-Warn "Pages may already be enabled — continuing"
    }

    # Set custom domain
    try {
        gh api "repos/$Username/$Repo/pages" `
            --method PUT `
            --field "cname=$Domain" 2>$null | Out-Null
        Write-OK "Custom domain set: $Domain"
    } catch {
        Write-Warn "Could not set domain via CLI — do it manually (see below)"
    }
} else {
    Write-Warn "GitHub CLI not installed — do GitHub Pages manually (see below)"
}

# ════════════════════════════════════════════════════════════
# DONE
# ════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "  ══════════════════════════════════════════════" -ForegroundColor DarkYellow
Write-Host "  ✓  ALL DONE!" -ForegroundColor Green
Write-Host "  ══════════════════════════════════════════════" -ForegroundColor DarkYellow
Write-Host ""
Write-Host "  ─── GITHUB PAGES (do this if not auto-done) ──" -ForegroundColor Yellow
Write-Host "  1. Go to: https://github.com/cadis11/nath-archives" -ForegroundColor Gray
Write-Host "  2. Settings → Pages → Source: main / (root) → Save" -ForegroundColor Gray
Write-Host "  3. Custom domain: nathdigitalarchive.com → Save" -ForegroundColor Gray
Write-Host "  4. Tick: Enforce HTTPS" -ForegroundColor Gray
Write-Host ""
Write-Host "  ─── GODADDY DNS (do this once) ───────────────" -ForegroundColor Yellow
Write-Host "  Login to GoDaddy → DNS for nathdigitalarchive.com" -ForegroundColor Gray
Write-Host "  Add these 4 A records (Name = @):" -ForegroundColor Gray
Write-Host "    185.199.108.153" -ForegroundColor Cyan
Write-Host "    185.199.109.153" -ForegroundColor Cyan
Write-Host "    185.199.110.153" -ForegroundColor Cyan
Write-Host "    185.199.111.153" -ForegroundColor Cyan
Write-Host "  Add 1 CNAME record:" -ForegroundColor Gray
Write-Host "    Name: www   →   Value: cadis11.github.io" -ForegroundColor Cyan
Write-Host ""
Write-Host "  ─── YOUR SITE WILL BE LIVE AT ────────────────" -ForegroundColor Yellow
Write-Host "  🌐 https://nathdigitalarchive.com" -ForegroundColor Cyan
Write-Host "  🔐 https://nathdigitalarchive.com/admin/" -ForegroundColor Cyan
Write-Host "     Login: keeper / gorakh108" -ForegroundColor Gray
Write-Host ""
Write-Host "  DNS can take 10–30 minutes to fully activate." -ForegroundColor Gray
Write-Host ""
