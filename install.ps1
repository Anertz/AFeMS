$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
git clone https://github.com/Anertz/AFeMS
if (Test-Path "AFeMS") {
    cd AFeMS
    (pwd).Path | clip
    Write-Host "Mods are installed!" -ForegroundColor Green
} else {
    Write-Host "Git clone was failed" -ForegroundColor Red
}
