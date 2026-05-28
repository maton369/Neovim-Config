# Neovim development environment setup script for Windows
# Run: powershell -ExecutionPolicy Bypass -File setup.ps1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "=== Neovim Environment Setup (Windows) ===" -ForegroundColor Cyan

# -----------------------------------------------------------
# 1. winget check
# -----------------------------------------------------------
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Error: winget is required. Install App Installer from Microsoft Store." -ForegroundColor Red
    exit 1
}

# -----------------------------------------------------------
# 2. Git
# -----------------------------------------------------------
Write-Host "[1/6] Git..." -ForegroundColor Yellow
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    winget install --id Git.Git -e --accept-package-agreements --accept-source-agreements
    $env:PATH = "$env:ProgramFiles\Git\cmd;$env:PATH"
} else {
    Write-Host "  Already installed: $(git --version)"
}

# -----------------------------------------------------------
# 3. Neovim
# -----------------------------------------------------------
Write-Host "[2/6] Neovim..." -ForegroundColor Yellow
if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
    winget install --id Neovim.Neovim -e --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "  Already installed: $(nvim --version | Select-Object -First 1)"
}

# -----------------------------------------------------------
# 4. Node.js
# -----------------------------------------------------------
Write-Host "[3/6] Node.js..." -ForegroundColor Yellow
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    winget install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "  Already installed: node $(node --version)"
}

# -----------------------------------------------------------
# 5. Python
# -----------------------------------------------------------
Write-Host "[4/6] Python..." -ForegroundColor Yellow
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    winget install --id Python.Python.3.12 -e --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "  Already installed: $(python --version)"
}

# -----------------------------------------------------------
# 6. CLI tools (ripgrep, fd, Rust)
# -----------------------------------------------------------
Write-Host "[5/6] CLI tools..." -ForegroundColor Yellow

if (-not (Get-Command rg -ErrorAction SilentlyContinue)) {
    winget install --id BurntSushi.ripgrep.MSVC -e --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "  ripgrep already installed"
}

if (-not (Get-Command fd -ErrorAction SilentlyContinue)) {
    winget install --id sharkdp.fd -e --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "  fd already installed"
}

if (-not (Get-Command rustc -ErrorAction SilentlyContinue)) {
    winget install --id Rustlang.Rustup -e --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "  Rust already installed: $(rustc --version)"
}

# C compiler (zig as cc for Treesitter)
if (-not (Get-Command zig -ErrorAction SilentlyContinue)) {
    winget install --id zig.zig -e --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "  zig already installed"
}

# -----------------------------------------------------------
# 7. Neovim config
# -----------------------------------------------------------
Write-Host "[6/6] Neovim config..." -ForegroundColor Yellow
$nvimConfigPath = "$env:LOCALAPPDATA\nvim"
if (-not (Test-Path "$nvimConfigPath\.git")) {
    if (Test-Path $nvimConfigPath) {
        Write-Host "  Backing up existing config to $nvimConfigPath.bak"
        Rename-Item $nvimConfigPath "$nvimConfigPath.bak"
    }
    git clone git@github.com:maton369/Neovim-Config.git $nvimConfigPath
    Write-Host "  Config cloned to $nvimConfigPath"
} else {
    Push-Location $nvimConfigPath
    git pull
    Pop-Location
    Write-Host "  Config updated"
}

Write-Host ""
Write-Host "=== Setup complete! ===" -ForegroundColor Green
Write-Host "Restart your terminal, then run 'nvim' to start."
Write-Host "Plugins will install automatically on first launch."
Write-Host ""
Write-Host "Note: If Treesitter compilation fails, ensure zig is in your PATH." -ForegroundColor Yellow
