# =============================================================
#  Nath Archives — Bulk PDF Upload Script (PowerShell 7)
#  Uploads multiple PDFs from a local folder to GitHub
# =============================================================

param(
    [Parameter(Mandatory)] [string]$Token,    # GitHub PAT
    [Parameter(Mandatory)] [string]$Repo,     # e.g. "yourname/nath-archives"
    [Parameter(Mandatory)] [string]$Folder,   # Local folder with PDFs
    [string]$Category  = "Scripture",
    [string]$Author    = "Traditional",
    [switch]$Featured
)

$Headers = @{
    Authorization  = "token $Token"
    "Content-Type" = "application/json"
    Accept         = "application/vnd.github.v3+json"
}

function Get-FileSha($path) {
    try {
        $r = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/contents/$path" `
                               -Headers $Headers -ErrorAction SilentlyContinue
        return $r.sha
    } catch { return $null }
}

function Upload-File($localPath, $remotePath, $message) {
    $bytes = [IO.File]::ReadAllBytes($localPath)
    $b64   = [Convert]::ToBase64String($bytes)
    $sha   = Get-FileSha $remotePath

    $body = @{ message = $message; content = $b64 }
    if ($sha) { $body.sha = $sha }

    Invoke-RestMethod `
        -Uri     "https://api.github.com/repos/$Repo/contents/$remotePath" `
        -Method  PUT `
        -Headers $Headers `
        -Body    ($body | ConvertTo-Json -Depth 3) | Out-Null
}

function Get-BooksJson {
    try {
        $r = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/contents/data/books.json" `
                               -Headers $Headers
        return [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($r.content -replace "`n",''))
        | ConvertFrom-Json
    } catch { return @() }
}

function Save-BooksJson($books) {
    $sha  = Get-FileSha "data/books.json"
    $json = $books | ConvertTo-Json -Depth 5
    $b64  = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($json))
    $body = @{ message = "Update catalog"; content = $b64 }
    if ($sha) { $body.sha = $sha }
    Invoke-RestMethod `
        -Uri     "https://api.github.com/repos/$Repo/contents/data/books.json" `
        -Method  PUT `
        -Headers $Headers `
        -Body    ($body | ConvertTo-Json) | Out-Null
}

# ── Main ───────────────────────────────────────────────────
Write-Host ""
Write-Host "  ॐ Nath Archives — Bulk Upload" -ForegroundColor DarkYellow
Write-Host "  Repo: $Repo | Folder: $Folder" -ForegroundColor Gray
Write-Host ""

$files = Get-ChildItem "$Folder\*.pdf" -ErrorAction SilentlyContinue
if (-not $files) {
    Write-Host "  No PDF files found in: $Folder" -ForegroundColor Red
    exit 1
}

Write-Host "  Found $($files.Count) PDF(s) to upload..." -ForegroundColor Cyan
$books = @(Get-BooksJson)
$uploaded = 0

foreach ($file in $files) {
    $safeName  = $file.Name -replace '[^a-zA-Z0-9._\-]','_'
    $remotePath = "books/$safeName"
    $title      = $file.BaseName -replace '[-_]',' '
    $id         = $file.BaseName -replace '[^a-zA-Z0-9]','_'

    Write-Host "  Uploading: $($file.Name)..." -NoNewline -ForegroundColor Gray

    try {
        Upload-File $file.FullName $remotePath "Add: $title"

        $existing = $books | Where-Object { $_.id -eq $id }
        $newEntry = [PSCustomObject]@{
            id          = $id
            title       = $title
            author      = $Author
            category    = $Category
            description = ""
            file        = $remotePath
            type        = "PDF"
            featured    = $Featured.IsPresent
            coverColor  = "#8B2500"
            addedDate   = (Get-Date -Format "yyyy-MM-dd")
        }

        if ($existing) {
            $books = $books | Where-Object { $_.id -ne $id }
        }
        $books += $newEntry
        $uploaded++
        Write-Host " ✓" -ForegroundColor Green
    } catch {
        Write-Host " ✗ $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "  Saving catalog ($($books.Count) total texts)..." -NoNewline -ForegroundColor Cyan
try {
    Save-BooksJson $books
    Write-Host " ✓" -ForegroundColor Green
} catch {
    Write-Host " ✗ $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "  ✓ Done! Uploaded $uploaded/$($files.Count) files." -ForegroundColor Green
Write-Host "  Changes will appear on the site in ~1 minute." -ForegroundColor Gray
Write-Host ""
