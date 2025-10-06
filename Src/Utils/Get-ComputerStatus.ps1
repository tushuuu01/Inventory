<#
    Командлет получения перечня компьютеров в домене с проверкой доступности компьютера по сети и управления через WinRM

    Ключи:
        -OUName - контейнер в ЕСК для получения объектов типа компьютер, если ключ не задан - будет использован OU текущего компьютера
        -ExcludeOU - исключить контейнеры с именами включающими ExcludeOU

    Если ключ -OUName не указан, будет возвращен перечень компьютеров из текущего OU

    Из домена, начиная с OU с именем OUName, получаются объекты типа компьютер.
    Дополнительно добавляются поля NetAccess и PSAccess, по умолчанию со значением $false
    Возращаемый список:
        ComputerName - имя компьютера
        ComputerDomain - домен компьютера
        ComputerOS - ОС
        ComputerDescription - описание
        NetAccess - доступ по сети
        PSAccess - доступ через WinRM
        CollectionDate - дата сбора
        ComputerOU - расположение компьютера в домене
        InvStatus = Неизвестно (используется при удаленном сборе)
    
    Новгородов Павел 10.2023
#>

function Get-ComputerStatus {
    [cmdletbinding()]
    Param(
        [parameter(ValueFromPipeline=$True)]
        [string]
        $OUName = "",
        [parameter(ValueFromPipeline=$True)]
        [string]
        $ExcludeOU = ""
        )
        process
            {
                #если параметр с наименованием OU не передан, получаем OU в котором расположен текущий компьютер
                if (-not $OUName)
                {
                    $current_ou = (Get-ADComputer -Identity $env:COMPUTERNAME).DistinguishedName -split ","
                    $OUName = $current_ou[1..$current_ou.Count] -join ","
                }
                
                #получаем перечень компьютеров из AD
                $computers = Get-ADComputer -SearchBase $OUName -Filter {enabled -eq "true"} -Properties Name, operatingSystem, Description, DistinguishedName | Where-Object "DistinguishedName" -notlike $ExcludeOU  | Where-Object "OperatingSystem"

                $computer_result = @()

                #дата время сбора 
                $collection_date = (Get-Date).ToShortDateString()

                    foreach ($computer in $computers)
                    {
                        #проверяем доступность компьютера по сети
                        $test_connect = Test-Connection -Count 1 -ComputerName $computer.Name -Quiet
                        if ($test_connect) { $test_ws = ((Test-WSMan -ComputerName $computer.Name -ErrorAction SilentlyContinue) -ne $null) }
                        else {$test_ws = $false}

                        #убираем из DistinguishedName имя компьютера
                        $ou = $computer.DistinguishedName -split ","

                        #формируем строку для записи в результат
                        $properties = [ordered]@{"ComputerName"  = $computer.Name; "ComputerDomain" = $env:USERDOMAIN; "ComputerOS"=$computer.operatingSystem; "ComputerDescription" = $computer.Description; "NetAccess"=$test_connect; "PSAccess"=$test_ws; "CollectionDate"=$collection_date;  "ComputerOU" = ($ou[1..$ou.Count] -join ","); "InvStatus"="Неизвестно"}
                        
                        $computer_result += New-Object -TypeName PSObject -Property $properties
                    }
            return $computer_result
            }
}

<#
    Примеры использования командлета. 
    Можно убрать комментарий и выполнить непосредственно данный скрипт для проверки работы командлета. При штатной работе все что расположено ниже должно быть закоментировано

    #Вернуть имена компьютеров из указанного OU доступные для управления через PS
    (Get-ComputersStatus -OUName "OU=KurganSNServers, OU=KurganSN, OU=Kurgan, DC=region, DC=cbr, DC=ru" | Where-Object -Property PSAccess).ComputerName

    #Получить список компьютеров в OU в котором расположен текущий компьютер
    Get-ComputersStatus -ExcludeOU "*OFFLine*"
#>

