git clone https://github.com/Anertz/AFeMS
if (Test-Path "AFeMS") {
    cd AFeMS
    (pwd).Path | clip
    Write-Host "Mods are installed!" -ForegroundColor DarkCyan
} else {
    Write-Host "Git clone was failed" -ForegroundColor Red
}
