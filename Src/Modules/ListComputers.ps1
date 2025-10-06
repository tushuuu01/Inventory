<#
    Сбор инвентаризационной информации
    Получить перечень компьютеров с которых будет собираться информация

    Параметр $InvComputerList:
        - файл с именами компьютеров
        - имена компьютеров через запятую

    Если параметр $InvComputerList пустой - будет получен перечень компьютеров из $InvOU
    
    Возвращает перечень компьютеров
#>
function ListComputers {
    Param (
        [array]$InvComputerList, 
        [string]$InvOU,
        [int]$DayOld
    )

    $result = $null

    #если передан параметр InvComputerList - файл
    if ($InvComputerList -like "file:*")
    {
        $InvComputerList = ($InvComputerList -replace "file:*", "").Trim()

        if (Test-Path $InvComputerList)
        {
            $result = Import-Csv -Path $InvComputerList -Header ComputerName
            $result = $result | select ComputerName, CollectionDate, NetAccess, PSAccess, InvStatus -Unique

            WriteLog "Получен перечень компьютеров из файла $InvComputerList"
        }
        else
        {
            WriteLog "Получен параметр InvComputerList. Файл $InvComputerList не найден. Прекращаем выполнение."
            break
        }
    }
    elseif ($InvComputerList)
    {
        WriteLog "Получен параметр InvComputerList. Количество компьютеров: $($InvComputerList.Count)"

        $InvComputerList = $InvComputerList | Sort-Object | Get-Unique

        $result = $InvComputerList | select @{Name = "ComputerName"; expression = {$_}}, CollectionDate, NetAccess, PSAccess, InvStatus
    }

    #если файл с именами компютеров не передан - получаем перечень компьютеров из $InvOU
    if (!$InvComputerList)
    {
        $result = Get-Computer -OUName $InvOU -LastLogonDay $DayOld | select ComputerName, CollectionDate, NetAccess, PSAccess, InvStatus

        if ($result)
        {
            WriteLog "Получен перечень компьютеров из OU $InvOU. Количество: $($result.Count)"
        }
    }

    return $result
}