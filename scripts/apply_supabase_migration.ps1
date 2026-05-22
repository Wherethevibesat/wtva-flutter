# Applies supabase/migrations/000_full_database.sql to your remote database.
#
# Usage (easiest - paste password when prompted):
#   cd c:\src\thisishtx
#   .\scripts\apply_supabase_migration.ps1
#
# Usage (password on command line):
#   .\scripts\apply_supabase_migration.ps1 -DbPassword 'your-db-password'
#
# Get password: Supabase Dashboard -> Project Settings -> Database -> Database password

param(
    [string]$DbPassword,
    [string]$ProjectRef = "wabtknktqnrxnffkgpzh",
    [switch]$ClipboardOnly
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent
$sqlFile = Join-Path $repoRoot "supabase\migrations\000_full_database.sql"

if (-not (Test-Path $sqlFile)) {
    Write-Error "SQL file not found: $sqlFile"
}

if ($ClipboardOnly) {
    Get-Content $sqlFile -Raw | Set-Clipboard
    Start-Process "https://supabase.com/dashboard/project/$ProjectRef/sql/new"
    Write-Host "SQL copied to clipboard. Opened Supabase SQL Editor - paste (Ctrl+V) and click Run."
    exit 0
}

if (-not $DbPassword) {
    Write-Host ""
    Write-Host "Supabase database password required."
    Write-Host "Find it: https://supabase.com/dashboard/project/$ProjectRef/settings/database"
    Write-Host ""
    $secure = Read-Host "Database password" -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    $DbPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
}

if ([string]::IsNullOrWhiteSpace($DbPassword)) {
    Write-Error "No password provided."
}

$encoded = [uri]::EscapeDataString($DbPassword)
$dbUrl = "postgresql://postgres:${encoded}@db.${ProjectRef}.supabase.co:5432/postgres"

Write-Host "Applying full database schema to project $ProjectRef ..."
Write-Host "  $sqlFile"
Write-Host ""

Push-Location $repoRoot
try {
    npx --yes supabase@latest db query --db-url $dbUrl -f $sqlFile
    if ($LASTEXITCODE -ne 0) {
        throw "Migration failed (exit $LASTEXITCODE). Check password and network."
    }
    Write-Host ""
    Write-Host "Migration applied successfully."
    Write-Host "Restart the app: flutter run"
}
finally {
    Pop-Location
}
