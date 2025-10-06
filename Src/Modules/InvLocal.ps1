<#
    Модуль сбора инвентаризационной информации.
    Локальная инвентаризация.

    Параметры:
        -InvLocalComputers - каталог сохранения файлов локальной инвентаризаци
        -InvLocalCompressFile - каталог сохранения файла архива с инвентаризационными данными, если задан данный параметр файлы из InvLocalComputers будут помещены в архив в папке InvLocalCompressFile
        -InvLocalDaysOld - считать старыми файлы инвентаризации старше заданного количества дней (по умолчанию 5 дней)
#>

function InvLocal {
    [cmdletbinding()]
    Param(
        [string]$InvLocalComputers,
        [string]$InvLocalCompressFile,
        [array]$InvTypeSelect,
        [int]$InvLocalDaysOld = 5,
        [boolean]$ExtendLog
    )

    #получаем список файлов инвентаризации в папке $InvLocalComputers
    $InvFilesOld = Get-ChildItem -Path $InvLocalComputers | Where-Object {$_.Name -match "$($env:COMPUTERNAME)\.\w\w\w\.csv"} 

    #получаем файлы инвентаризации в папке $InvLocalComputers старше $InvLocalDaysOld из них возвращаем дату изменения самого старого файла
    $InvLastDate = $InvFilesOld | select LastWriteTime | Where-Object -Property LastWriteTime -lt (Get-Date).AddDays(-$InvLocalDaysOld) | sort LastWriteTime | select -Last 1

    #если файлы инвентаризации есть и нет старых файлов - прекращаем выполнение, инвентаризацию собирать не надо
    if ($InvFilesOld -and !$InvLastDate)
    {
        WriteLog "Найдены актуальные файлы инвентаризации (актуальность $InvLocalDaysOld дней). Завершаем выполнение"
        return
    }

    if ($InvFilesOld) 
    {
        WriteLog "Удаляем старые файлы инвентаризации"
        $InvFilesOld | Remove-Item
    }

    #если файлов инвентаризации нет, либо они старые - запускаем инвентаризацию
    WriteLog "Путь сохранения данных инвентаризации $InvLocalComputers"
    WriteLog "Путь сохранения ZIP архива с данными инвентаризации $InvLocalCompressFile"

    #получаем данные инвентаризации, полученный результат сохраняем в отдельные файлы по типу информации
    $inv_res = $null

    #если включен расширенный лог
    if ($ExtendLog)
    {
        $inv_res = Get-Inventory -InvSelectType $InvTypeSelect.PsName
    }
    else
    {
        $inv_res = Get-Inventory -LogFileName $global:InvLogFile -InvSelectType $InvTypeSelect.PsName
    }

    if (!$inv_res)
    {
        WriteLog "Нет данных инвентаризации для сохранения"
        return
    }

    WriteLog "Сохраняем файлы инвентаризации"
    $inv_res | ForEach-Object {if ($_.Data) {$_.Data | Export-csv -Path (Join-Path $InvLocalComputers "$($env:COMPUTERNAME).$($_.Type).csv") -Encoding UTF8 -NoTypeInformation}}

    #если задан путь для сохранения фалов в архиве и путь существует - создаем архив и добавляем в него файлы инвентаризации
    if ($InvLocalCompressFile -and (Test-Path $InvLocalCompressFile))
    {
        WriteLog "Старт создания ZIP архива в папке $InvLocalCompressFile"

        #получаем список файлов для включения в архив
        $files_to_zip = $inv_res | select @{Name = "FileName"; expression={(Join-Path $InvLocalComputers "$($env:COMPUTERNAME).$($_.Type).csv")}}

        Add-Type -AssemblyName "System.IO.Compression.FileSystem"

        $file_zip = Join-Path $InvLocalCompressFile "inv.$($env:COMPUTERNAME).zip"

        if (Test-Path $file_zip)
        {
            WriteLog "Удаляем предыдущий ZIP архив $file_zip"
            Remove-Item $file_zip -ErrorAction SilentlyContinue
        }

        #создаем архив
        $zip = [System.IO.Compression.ZipFile]::Open($file_zip, "create")
        $zip.Dispose()

        #добавляем в архив файлы
        $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
        $zip = [System.IO.Compression.ZipFile]::Open($file_zip, "update")
        $files_to_zip | ForEach-Object{[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FileName, (Split-Path $_.FileName -Leaf), $compressionLevel)}

        WriteLog "Создан ZIP архив $file_zip"
        $zip.Dispose()
    }
    else 
    {
        WriteLog "Не найдена папка для создания ZIP архива $InvLocalCompressFile"
    }

    WriteLog "Завершение локальной процедуры сбора"
}
