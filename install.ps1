$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
git clone https://github.com/Anertz/AFeMS
if (Test-Path "AFeMS") {
    cd AFeMS
    (pwd).Path | clip
    echo "ModsのインストールとPathのコピーが完了しました"
} else {
    Write-Host "Git clone に失敗しました。" -ForegroundColor Red
}
