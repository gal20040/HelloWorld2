param (
    [Parameter(Mandatory = $true)]
    [string]$FILE_KEY
)

# Формируем команду проверки
# Перенаправляем вывод в $null, чтобы не засорять консоль JSON-ответом
aws s3api head-object `
    --bucket $R2_BUCKET `
    --key $FILE_KEY `
    --endpoint-url $R2_ENDPOINT #`
    #> $null 2>&1

# Проверяем код возврата
# 0 = файл существует, иначе (обычно 255) = файл не найден или ошибка
if ($LASTEXITCODE -eq 0) {
    Write-Host "Файл '$FILE_KEY' существует. Удаляем..."
    
    # Команда удаления
    aws s3 rm `
        "s3://$R2_BUCKET/$FILE_KEY" `
        --endpoint-url $R2_ENDPOINT
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Файл '$FILE_KEY' успешно удален."
    } else {
        Write-Error "Ошибка при удалении файла '$FILE_KEY'."
        return
    }
} else {
    Write-Host "Файл '$FILE_KEY' не найден. Не удаляем."
}

# Заново заливаем файл
aws s3 cp `
    $FILE_KEY `
    s3://$R2_BUCKET/ `
    --endpoint-url $R2_ENDPOINT `
    --progress-frequency 1 `
    --progress-multiline
