param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({
        if ($_ -replace '\s', '' -eq '') {
            throw "Параметр не должен состоять только из пробелов."
        }
        return $true
    })]
    [string]$ANDROID_CODE
)

$allKeys = aws s3api list-objects-v2 `
    --bucket $R2_BUCKET `
    --endpoint-url $R2_ENDPOINT `
    --query 'Contents[].Key' `
    --output text

if (-not $allKeys) {
    throw "Не удалось получить список файлов из бакета."
    return
}

#$allKeys

# Ищем совпадение по подстроке
# Разбиваем вывод на массив строк (каждый файл - отдельная строка)
$foundFiles = @()
$subStringToFind = "*$ANDROID_CODE*"
foreach ($key in $allKeys -split "`t") {
    if ($key -like $subStringToFind) { # .tar.zst
        $foundFiles += $key
    }
}

#$foundFiles.Count

if ($foundFiles.Count -eq 0) {
    throw "Нет файлов, содержащих '$subStringToFind'."
    return
}

Write-Host "✅ Найдено '$($foundFiles.Count)' файлов с подстрокой '$subStringToFind':" -ForegroundColor Yellow # .tar.zst
#$foundFiles

$folderPath = "C:\Users\gal\Downloads\!aab\$ANDROID_CODE"
Write-Host "📁 Создаём папку:" -ForegroundColor Green
mkdir -p $folderPath
Write-Host ""

foreach ($targetKey in $foundFiles) {
    Write-Host "🎯 Выбран файл для скачивания: $targetKey" -ForegroundColor Green

    $archFile = Split-Path -Path $targetKey -Leaf                         #zstFile
    Write-Host "🗜️ Имя конечного файла: $archFile" -ForegroundColor Green #zstFile
    $fullPath = "$folderPath\$archFile"

    .\maintenance_scripts\DownloadFromR2.ps1 $targetKey $folderPath $archFile

    if ($?) { # Проверка успеха последней команды
        Write-Host "🎉 Скачивание завершено: '$fullPath'" -ForegroundColor Green #zstFile
    } else {
        throw "❌ Ошибка при скачивании $targetKey в '$fullPath'."
        return
    }
    Write-Host ""

    $ext = [System.IO.Path]::GetExtension($fullPath) -replace '\.', ''
    
    Write-Host "🗃️ Расширение файла: '$ext'" -ForegroundColor Green

    $validExtensions = @("7z", "zip", "zst")

    if ($ext -in $validExtensions) {
        if ($ext -eq "zst") {
            $folderForUncompressedFiles = "aab"
            Write-Host "🗃️ $folderForUncompressedFiles" -ForegroundColor Green
        } else {
            $folderForUncompressedFiles = $archFile.Substring($ANDROID_CODE.Length + 5, $archFile.Length - $ANDROID_CODE.Length - 5)
            Write-Host "🗃️ $folderForUncompressedFiles" -ForegroundColor Green
            $folderForUncompressedFiles = $folderForUncompressedFiles.Substring(0, $folderForUncompressedFiles.Length - 1 - $ext.Length)
            Write-Host "🗃️ $folderForUncompressedFiles" -ForegroundColor Green
        }

        Write-Host "🗜️ Распаковка файла '$archFile' в '$folderPath\$folderForUncompressedFiles'" -ForegroundColor Green
        7z x "$fullPath" -o"$folderPath\$folderForUncompressedFiles"
        Write-Host ""

        if ($ext -eq "zst") {
            # Взять только имя без расширения ".zst"
            $tarFile = $archFile.Substring(0, $archFile.Length - 4)

            Write-Host "🗜️ Распаковка файла '$tarFile' в '$folderPath\'" -ForegroundColor Green
            7z x "$folderPath\$folderForUncompressedFiles\$tarFile" -o"$folderPath\aab"
            Write-Host ""

            Write-Host "🗜️ Удаляем файл в '$folderPath\$tarFile'" -ForegroundColor Green
            rm "$folderPath\$folderForUncompressedFiles\$tarFile"
        }
        Write-Host "🎉 Файл '$archFile' распакован в '$folderPath\'." -ForegroundColor Green
    } else {
        Write-Error "❌ Неизвестное расширение: '$ext'. Архив надо распаковать вручную."
    }
}

Write-Host "🎉 Готово." -ForegroundColor Green
ls "$folderPath\"

##if ($foundFiles.Count -gt 0) {
##    throw "Найдено несколько файлов, содержащих '.tar.zst'."
##}
#
#$targetKey = $foundFiles | Select-Object -First 1
#Write-Host "🎯 Выбран для скачивания: $targetKey" -ForegroundColor Green
#
#$zstFile = Split-Path -Path $targetKey -Leaf
#Write-Host "🗜️ Имя конечного файла: $zstFile" -ForegroundColor Green
#
#aws s3 cp `
#    "s3://$R2_BUCKET/$targetKey" `
#    "$folderPath\$zstFile" `
#    --endpoint-url $R2_ENDPOINT `
#    --progress-frequency 1 #`
#    #--progress-multiline
#
#if ($?) { # Проверка успеха последней команды
#    Write-Host "🎉 Скачивание завершено: $folderPath\$zstFile" -ForegroundColor Green
#} else {
#    throw "❌ Ошибка при скачивании $targetKey в $folderPath\$zstFile."
#    return
#}
#
## Взять с начала, без последних 4х знаков (без расширения ".zst")
#$tarFile = $zstFile.Substring(0, $zstFile.Length - 4) 
#
#Write-Host "🗜️ Распаковка файла '$zstFile' в '$folderPath\'" -ForegroundColor Green
#7z x "$folderPath\$zstFile" -o"$folderPath"
#
#Write-Host "🗜️ Распаковка файла '$tarFile' в '$folderPath\'" -ForegroundColor Green
#7z x "$folderPath\$tarFile" -o"$folderPath"
#
#Write-Host "🎉 Готово." -ForegroundColor Green
#ls "$folderPath\"
#
#Write-Host "🗜️ Удаляем файл в '$folderPath\$zstFile'" -ForegroundColor Green
#rm "$folderPath\$tarFile"
#
#ls "$folderPath\"

## Проверяем код возврата
## 0 = файл существует, иначе (обычно 255) = файл не найден или ошибка
#if ($LASTEXITCODE -eq 0) {
#    Write-Host "Файл '$FILE_KEY' существует. Удаляем..."
#    
#    # Команда удаления
#    aws s3 rm `
#        "s3://$R2_BUCKET/$FILE_KEY" `
#        --endpoint-url $R2_ENDPOINT
#    
#    if ($LASTEXITCODE -eq 0) {
#        Write-Host "Файл '$FILE_KEY' успешно удален."
#    } else {
#        throw "Ошибка при удалении файла '$FILE_KEY'."
#        return
#    }
#} else {
#    Write-Host "Файл '$FILE_KEY' не найден. Не удаляем."
#}
#
## Заново заливаем файл
#aws s3 cp `
#    $FILE_KEY `
#    s3://$R2_BUCKET/ `
#    --endpoint-url $R2_ENDPOINT `
#    --progress-frequency 1 `
#    --progress-multiline
#
#
#aws s3 cp `
#    $FILE_KEY `
#    s3://$R2_BUCKET/ `
#    --endpoint-url $R2_ENDPOINT `
#    --progress-frequency 1 `
#    --progress-multiline
#
#aws s3 cp `
#  "s3://$R2_BUCKET/$FILE_KEY" `
#  "~/Downloads/" `
#  --endpoint-url "$R2_ENDPOINT" `
#  --progress-frequency 1 `
#  --progress-multiline
#
#
#7z x C:\Users\gal\Downloads\1055072.aab_1055072.aab.9.tar.zst -oC:\Users\gal\Downloads\2\
#7z x C:\Users\gal\Downloads\2/1055072.aab_1055072.aab.9.tar -oC:\Users\gal\Downloads\2\
