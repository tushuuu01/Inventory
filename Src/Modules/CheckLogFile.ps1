<#
    Сбор инвентаризационной информации
    Проверка возможности ведения файла протокола
    Возвращает имя файла протокола, если каталог размещения файла протокола существует
    Если каталог существует - выполняется очистка каталога, остаются последние 20 файлов
#>

function CheckLogFile {
    Param (
        [string]$LogFilePath,
        [string]$StartType,
        [int]$MaxLenLog = 20Kb
    )

    $result = $null

    if ($LogFilePath)
    {
        if (!(Test-Path $LogFilePath))
        {
            Write-Host "Каталог $LogFilePath ведения лога не найден. Лог файл не будет формироваться."
            return $result
        }

        #если локальный сбор
        if ($StartType -eq "InvLocal")
        {
            $result = Join-Path $LogFilePath "inv_$($env:COMPUTERNAME).log"
            
            if (Test-Path $result)
            {
                #получаем свойства файла
                $LogFile = Get-Item -Path $result

                #если размер файла превышет заданный
                if ($LogFile.Length -ge $MaxLenLog)
                {
                    Remove-Item -Path $result -ErrorAction Ignore
                }
            }
        }
        #удаленный сбор или формирования результирующих файлов
        else
        {
            $result = Join-Path $LogFilePath "inv_$((Get-Date).ToString('yyyy-MM-dd')).log"

            #удаление старых лог файлов
            WriteLog "Очистка каталог LOG $LogFilePath - оставляем 20 последних файлов"
            Get-ChildItem -Path $LogFilePath | Sort-Object LastWriteTime -Descending | select -Skip 20 | Remove-Item
        }

        return $result
    }
}
