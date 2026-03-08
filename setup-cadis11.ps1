# =============================================================
#  Nath Digital Archives — SETUP & DEPLOY
#  For: cadis11/nath-archives
#  Run this from: C:\Users\USER\Downloads\nath-archives
#  PowerShell 7
# =============================================================

# ── Helpers ────────────────────────────────────────────────
function Write-Step { param($msg) Write-Host "`n► $msg" -ForegroundColor Cyan }
function Write-OK   { param($msg) Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "  ⚠ $msg" -ForegroundColor Yellow }
function Write-Err  { param($msg) Write-Host "  ✗ $msg" -ForegroundColor Red; exit 1 }

$Username = "cadis11"
$Repo     = "nath-archives"
$RepoUrl  = "https://github.com/$Username/$Repo.git"
$PagesUrl = "https://$Username.github.io/$Repo/"
$Folder   = "C:\Users\USER\Downloads\nath-archives"

# ── Banner ──────────────────────────────────────────────────
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor DarkYellow
Write-Host "  ║     ॐ  NATH DIGITAL ARCHIVES             ║" -ForegroundColor DarkYellow
Write-Host "  ║     Setup & Deploy → cadis11             ║" -ForegroundColor DarkYellow
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor DarkYellow
Write-Host ""

# ── Step 1: Navigate to folder ──────────────────────────────
Write-Step "Navigating to project folder…"
if (-not (Test-Path $Folder)) {
    Write-Err "Folder not found: $Folder`n  Make sure you extracted the files there."
}
Set-Location $Folder
Write-OK "In folder: $Folder"

# ── Step 2: Rename files correctly ──────────────────────────
Write-Step "Renaming files to correct names…"

# index 1.html  →  index.html  (public portal)
if (Test-Path "index 1.html") {
    if (Test-Path "index.html") { Remove-Item "index.html" -Force }
    Rename-Item "index 1.html" "index.html"
    Write-OK "'index 1.html'  →  index.html  (public portal)"
} elseif (Test-Path "index.html") {
    Write-OK "index.html already exists — skipping rename"
} else {
    Write-Warn "'index 1.html' not found — make sure it's in $Folder"
}

# index 2.html  →  admin\index.html  (admin panel)
if (-not (Test-Path "admin")) {
    New-Item -ItemType Directory -Name "admin" | Out-Null
    Write-OK "Created admin\ folder"
}

if (Test-Path "index 2.html") {
    if (Test-Path "admin\index.html") { Remove-Item "admin\index.html" -Force }
    Move-Item "index 2.html" "admin\index.html"
    Write-OK "'index 2.html'  →  admin\index.html  (admin panel)"
} elseif (Test-Path "admin\index.html") {
    Write-OK "admin\index.html already exists — skipping rename"
} else {
    Write-Warn "'index 2.html' not found — make sure it's in $Folder"
}

# ── Step 3: Create required folders ────────────────────────
Write-Step "Creating required folders…"
@("books", "covers", "data") | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Name $_ | Out-Null
        Write-OK "Created $_\"
    } else {
        Write-OK "$_\ already exists"
    }
}

# ── Step 4: Create books.json if missing ───────────────────
if (-not (Test-Path "data\books.json")) {
    "[]" | Set-Content "data\books.json" -Encoding UTF8
    Write-OK "Created data\books.json (empty catalog)"
} else {
    Write-OK "data\books.json already exists"
}

# ── Step 5: Create .gitignore ───────────────────────────────
Write-Step "Creating .gitignore…"
@"
*.DS_Store
Thumbs.db
.env
*.log
node_modules/
"@ | Set-Content ".gitignore" -Encoding UTF8
Write-OK ".gitignore created"

# ── Step 6: Create README ───────────────────────────────────
@"
# ॐ Nath Digital Archives

Sacred texts and teachings of the Nath Sampradaya, rooted in the immortal Mahayogi Gorakhnath.

**Live Archive:** $PagesUrl

## Admin Login
- Username: `keeper`
- Password: `gorakh108`

## Alakh Niranjan 🔥
"@ | Set-Content "README.md" -Encoding UTF8
Write-OK "README.md created"

# ── Step 7: Check Git ───────────────────────────────────────
Write-Step "Checking Git installation…"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Err "Git is not installed!`n  Install it from: https://git-scm.com/download/win`n  Then re-run this script."
}
Write-OK "Git found: $(git --version)"

# ── Step 8: Init Git ────────────────────────────────────────
Write-Step "Initializing Git repository…"
if (Test-Path ".git") {
    Write-Warn ".git already exists — skipping init"
} else {
    git init
    Write-OK "Git initialized"
}

# ── Step 9: Stage all files ─────────────────────────────────
Write-Step "Staging all files…"
git add .
Write-Host ""
git status --short
Write-OK "Files staged"

# ── Step 10: Commit ─────────────────────────────────────────
Write-Step "Creating commit…"
git commit -m "Initial commit: Nath Digital Archives OM"
git branch -M main
Write-OK "Commit created on branch: main"

# ── Step 11: Connect remote ─────────────────────────────────
Write-Step "Connecting to GitHub: $RepoUrl"
$remotes = git remote 2>$null
if ($remotes -contains "origin") {
    git remote set-url origin $RepoUrl
    Write-Warn "Remote 'origin' updated to: $RepoUrl"
} else {
    git remote add origin $RepoUrl
    Write-OK "Remote added: $RepoUrl"
}

# ── Step 12: Push ───────────────────────────────────────────
Write-Step "Pushing to GitHub…"
Write-Host "  (A browser window or credential prompt may open)" -ForegroundColor Gray
Write-Host ""

git push -u origin main

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "  Push failed. Try these fixes:" -ForegroundColor Red
    Write-Host ""
    Write-Host "  FIX A — Login with GitHub CLI:" -ForegroundColor Yellow
    Write-Host "    winget install GitHub.cli" -ForegroundColor Gray
    Write-Host "    gh auth login" -ForegroundColor Gray
    Write-Host "    (then re-run this script)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  FIX B — Use a Personal Access Token:" -ForegroundColor Yellow
    Write-Host "    1. Go to: https://github.com/settings/tokens/new" -ForegroundColor Gray
    Write-Host "    2. Check 'repo' scope, generate token" -ForegroundColor Gray
    Write-Host "    3. Run: git push -u origin main" -ForegroundColor Gray
    Write-Host "    4. When prompted for password, paste the token" -ForegroundColor Gray
    exit 1
}

Write-OK "Pushed to GitHub successfully!"

# ── Step 13: Enable GitHub Pages ────────────────────────────
Write-Step "Enabling GitHub Pages…"
$hasGhCli = Get-Command gh -ErrorAction SilentlyContinue
if ($hasGhCli) {
    try {
        $pagesBody = '{"source":{"branch":"main","path":"/"}}'
        gh api "repos/$Username/$Repo/pages" `
            --method POST `
            --input - <<< $pagesBody 2>$null
        Write-OK "GitHub Pages enabled automatically!"
    } catch {
        Write-Warn "Auto-enable failed — do it manually (see below)"
    }
} else {
    Write-Warn "GitHub CLI not installed — enable Pages manually:"
}

# ── Done ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ═══════════════════════════════════════════════" -ForegroundColor DarkYellow
Write-Host "  ✓  ALL DONE!" -ForegroundColor Green
Write-Host "  ═══════════════════════════════════════════════" -ForegroundColor DarkYellow
Write-Host ""
Write-Host "  🌐 Public Archive:" -ForegroundColor White
Write-Host "     $PagesUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "  🔐 Admin Panel:" -ForegroundColor White
Write-Host "     $($PagesUrl)admin/" -ForegroundColor Cyan
Write-Host ""
Write-Host "  ⏳ GitHub Pages takes 1–3 minutes to go live." -ForegroundColor Gray
Write-Host ""
Write-Host "  ── IF PAGES IS NOT AUTO-ENABLED ──────────────" -ForegroundColor DarkYellow
Write-Host "  1. Go to: https://github.com/cadis11/nath-archives" -ForegroundColor Gray
Write-Host "  2. Click: Settings → Pages" -ForegroundColor Gray
Write-Host "  3. Source: Deploy from branch" -ForegroundColor Gray
Write-Host "  4. Branch: main  |  Folder: / (root)" -ForegroundColor Gray
Write-Host "  5. Click Save" -ForegroundColor Gray
Write-Host ""
Write-Host "  ── ADMIN LOGIN ────────────────────────────────" -ForegroundColor DarkYellow
Write-Host "  Username: keeper" -ForegroundColor Gray
Write-Host "  Password: gorakh108" -ForegroundColor Gray
Write-Host ""
