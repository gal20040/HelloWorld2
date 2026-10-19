param (
    [Parameter(Mandatory = $true)]
    [string]$R2_FILE_NAME,

    [Parameter(Mandatory = $true)]
    [string]$LOCAL_FOLDER_PATH,

    [Parameter(Mandatory = $true)]
    [string]$LOCAL_FILE_NAME
)

Write-Host "🗜️ Скачиваем '$R2_FILE_NAME' в '$LOCAL_FILE_NAME'" -ForegroundColor Green

aws s3 cp `
    "s3://$R2_BUCKET/$R2_FILE_NAME" `
    "$LOCAL_FOLDER_PATH\$LOCAL_FILE_NAME" `
    --endpoint-url $R2_ENDPOINT `
    --progress-frequency 1 #`
    #--progress-multiline
