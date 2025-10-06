<#
    Сбор инвентаризационной информации
    Командлет получения перечня компьютеров в домене

    Ключи:
        -OUName - OU для получения объектов типа компьютер
        -ExcludeOU - исключить контейнеры с именами включающими ExcludeOU
        -LastLogonDay - количество дней для определения старых УЗ компьютеров (LastLogonDate старше текущая дата - LastLogonDay)

    Если ключ -OUName не указан, будет возвращен перечень компьютеров из текущего OU

    Из домена, начиная с OU с именем OUName, получаются объекты типа компьютер.
    Дополнительно добавляются поля NetAccess и PSAccess, по умолчанию со значением $false
    Возращаемый список:
        ComputerName - имя компьютера
        ComputerDomain - домен компьютера
        ComputerOS - ОС
        ComputerDescription - описание
        NetAccess = Неизвестно
        PSAccess = Неизвестно
        CollectionDate - дата сбора
        ComputerOU - расположение компьютера в домене
        InvStatus = Неизвестно (используется при удаленном сборе)
#>

function Get-Computer {
    [cmdletbinding()]
    Param(
        [parameter(ValueFromPipeline=$True)]
        [string]
        $OUName = "",
        [parameter(ValueFromPipeline=$True)]
        [string]
        $ExcludeOU = "",
        [parameter(ValueFromPipeline=$True)]
        [int]$LastLogonDay
        )
        process
            {
                #если параметр с наименованием OU не передан, получаем OU в котором расположен текущий компьютер
                if (-not $OUName)
                {
                    $current_ou = (Get-ADComputer -Identity $env:COMPUTERNAME).DistinguishedName -split ","
                    $OUName = $current_ou[1..$current_ou.Count] -join ","
                 }
                
                $collection_date = (Get-Date).ToString("dd.MM.yyyy")

                #дата устаревания УЗ компьютеров
                if ($LastLogonDay)
                {
                    #если параметр передан
                    $LastLogonDateOld = (Get-Date).AddDays(-$LastLogonDay)
                }
                else
                {
                    #если параметр не передан
                    $LastLogonDateOld = 0
                }

                #получаем перечень компьютеров из AD
                $computers = Get-ADComputer -SearchBase $OUName -Filter {enabled -eq "true" -and LastLogonDate -gt $LastLogonDateOld} -Properties Name, operatingSystem, Description, DistinguishedName | `
                                                 Where-Object "DistinguishedName" -notlike $ExcludeOU  | Where-Object "OperatingSystem"

                $computers = $computers | select @{Name="ComputerName"; expression={$_.Name.ToUpper()}},`
                                                 @{Name="ComputerDomain"; expression={$env:USERDOMAIN}},`   
                                                 @{Name="ComputerOS"; expression={$_.operatingSystem}},`
                                                 @{Name="ComputerDescription"; expression={$_.Description}},`
                                                 @{Name="NetAccess"; expression={"Неизвестно"}},`
                                                 @{Name="PSAccess"; expression={"Неизвестно"}},`
                                                 @{Name="CollectionDate"; expression={$collection_date}},`
                                                 @{Name="ComputerOU"; expression={($_.DistinguishedName -split ",")[1..100] -join ","}},`
                                                 @{Name="InvStatus"; expression={"Неизвестно"}}

            return $computers
            }
}
