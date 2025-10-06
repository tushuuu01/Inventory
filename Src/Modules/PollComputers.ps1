<#
    Сбор инвентаризационной информации
    Опрос компьютеров по сети - сбор инвентаризационной информации
    Возвращает перчень копьютеров с заполненным статусов сбора и доступности по сети
#>

function PollComputers {
    Param (
        [array]$ComputerList, 
        [string]$SaveInvPath, 
        [array]$InvTypeSelect,
        [boolean]$ExtendLog,
        $InvRemoteDayOld
    )

    #если параметр $InvRemoteDayOld больше 0 - будем проверять наличие актуальных файлов для компьютера
    if ($InvRemoteDayOld -gt 0) {

        WriteLog "Получаем перечень актуальных файлов инвентаризации (актуальность $InvRemoteDayOld дней)"
        #получаем перечень файлов в каталоге $SaveInvPath с датой изменения больше чем $InvLocalDaysOld дней
        $InvFilesOld = Get-ChildItem -Path $SaveInvPath | Where-Object {$_.Name -match '\.\w\w\w\.csv' -and $_.LastWriteTime -ge (Get-Date).AddDays(-$InvRemoteDayOld)} | select Name, LastWriteTime
    }

    #счетчик прогресса
    $i = 1
    #количество компьютеров
    $count = $ComputerList.Count

    #опрашиваем компьютеры
    foreach($computer in $ComputerList.ComputerName)
    {

        if ($InvFilesOld)
        {
            #проверяем наличие файлов инвентаризации от компьютера свежее чем текущая дата - $InvLocalDaysOld
            $InvLastDate = $InvFilesOld | Where-Object {$_.Name -like "*$computer*"} | sort LastWriteTime | select -Last 1

            if ($InvLastDate) {
                WriteLog "Для компьютера $computer найдены актуальные данные инвентаризации: $($InvLastDate.LastWriteTime) - пропускаем сбор."
                Continue
            }
        }

        Write-Progress -Activity "Сбор инвентаризации $i из $count" -Status "Проверяем доступность компьютера $computer" -PercentComplete ([System.Int32]($i/$count*100))

        #проверяем доступность компьютера по сети и управления через WinRM
        WriteLog "Проверяем доступность компьютера $computer"

        $test_connect = Test-Connection -Count 1 -ComputerName $computer -Quiet

        if ($test_connect)
        {
            $test_ws = ((Test-WSMan -ComputerName $computer -ErrorAction SilentlyContinue) -ne $null)
        }
        else
        {
            $test_ws = $false
        }

        #проставляем статус компьютера в перечене компьютеров
        ($ComputerList | Where-Object ComputerName -like $computer).NetAccess = $test_connect
        ($ComputerList | Where-Object ComputerName -like $computer).PSAccess = $test_ws

        WriteLog "Компьютер $computer доступен по сети $test_connect доступно управление через WinRM $test_ws"

        #если компьютер доступен для управления через WinRM начинаем опрос
        if ($test_ws)
        {
            Write-Progress -Activity "Сбор инвентаризации $i из $count" -Status "Опрашиваем $computer" -PercentComplete ([System.Int32]($i/$count*100))

            WriteLog "Опрашиваем $computer"

            #получаем данные инвентаризации, полученный результат сохраняем по каждому компьютеру в отдельный файл по типу информации
            #собираем инвентаризацию
            $inv_res = $null

            #если включен расширенный лог
            if ($ExtendLog)
            {
                $inv_res = Get-Inventory -ComputerName $computer -InvSelectType $InvTypeSelect.PsName -LogFileName $global:InvLogFile
            }
            else
            {
                $inv_res = Get-Inventory -ComputerName $computer -InvSelectType $InvTypeSelect.PsName
            }

            $inv_res | ForEach-Object {if ($_.Data) {$_.Data | Export-csv -Path (Join-Path $SaveInvPath "$($Computer).$($_.Type).csv") -Encoding UTF8 -NoTypeInformation}}

            #проставляем статус опроса компьютера, если получена инвентаризация $inv_swr - статус ОК, иначе Ошибка
            if ($inv_res)
            {
                ($ComputerList | Where-Object ComputerName -like $computer).InvStatus = "OK"
            }
            else
            {
                ($ComputerList | Where-Object ComputerName -like $computer).InvStatus = "Ошибка"
            }
        }

        $i++
    } #foreach

    Write-Progress -Completed -Activity "Опрос завершен"

    return $ComputerList
}
