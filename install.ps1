$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001
git clone https://github.com/Anertz/AFeMS
if (Test-Path "AFeMS") {
    cd AFeMS
    (pwd).Path | clip
    Write-Host "ModsのインストールとPathのコピーが完了しました"
} else {
    Write-Host "Git clone に失敗しました。" -ForegroundColor Red
}
