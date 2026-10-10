# ==============================================================================
# PowerShell Launcher for QuestaSim on Windows
# Usage:
#   .\run.ps1         # Run in GUI mode
#   .\run.ps1 -Batch  # Run in CLI batch mode
#   .\run.ps1 -Lint   # Run static lint check
#   .\run.ps1 -Clean  # Clean build artifacts
# ==============================================================================

param(
    [switch]$Batch,
    [switch]$Lint,
    [switch]$Clean
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

if ($Clean) {
    Write-Host "Cleaning simulation directory..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue work, transcript, *.wlf, *.log, modelsim.ini, covhtmlreport, vsim.dbg
    Write-Host "Clean finished." -ForegroundColor Green
    exit
}

if ($Lint) {
    Write-Host "Running Static Lint Checks..." -ForegroundColor Cyan
    Write-Host "--- 1. Python Rule-based Checker ---" -ForegroundColor Yellow
    python "$ScriptDir\..\scripts\check_lint.py" "$ScriptDir\..\rtl\aes_128_gcm_all.sv"

    Write-Host "`n--- 2. QuestaSim Built-in Compiler Lint ---" -ForegroundColor Yellow
    if (Get-Command vsim -ErrorAction SilentlyContinue) {
        vsim -c -do "do ../scripts/lint.do; quit -f"
    } else {
        Write-Host "[NOTE] 'vsim' not in system PATH. To run in QuestaSim GUI, open QuestaSim and run:" -ForegroundColor Magenta
        Write-Host "       cd `"$ScriptDir`"" -ForegroundColor Magenta
        Write-Host "       do ../scripts/lint.do" -ForegroundColor Magenta
    }
    exit
}

if (Get-Command vsim -ErrorAction SilentlyContinue) {
    if ($Batch) {
        Write-Host "Running QuestaSim in Batch Mode..." -ForegroundColor Cyan
        vsim -c -do "do ../scripts/run.do; quit -f"
    } else {
        Write-Host "Running QuestaSim in GUI Mode..." -ForegroundColor Cyan
        vsim -gui -do "do ../scripts/run.do"
    }
} else {
    Write-Host "[NOTE] 'vsim' not found in PATH." -ForegroundColor Yellow
    Write-Host "Please start QuestaSim from Desktop/Start Menu and enter in transcript:" -ForegroundColor Cyan
    Write-Host "  cd `"$ScriptDir`"" -ForegroundColor Green
    Write-Host "  do ../scripts/run.do" -ForegroundColor Green
}
