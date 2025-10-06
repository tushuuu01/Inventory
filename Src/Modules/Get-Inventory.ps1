<#
    Сбор инвентаризационной информации
    Командлет сбора инвентаризационной информации
    
    Варианты запуска:
        - локально (без указания имени компьютера) 
        - удаленно (с ключом -COMPUTERNAME)

    Результат выполнения: массив (тип информации; данные (список))
                          тип информации - три символа определяющие тип информации
                          данные - список данных с определенными полями для каждого типа информации

    Параметр InvSelectType - список имен модулей из каталога Get-Inventory-Module, которые будут использованы для сбора инвентаризации - имена модулей из каталога модулей

    Параметр LogFileName - имя лог файла, если задано - выполнение запросов к WMI будет протоколироваться

    Скрипты сбора расположены в каталоге модулей, код модулей загружается и создаются функции с именами "Get-Inv-xxx"
#>

Function Get-Inventory
{
    [CmdletBinding()]
    param (
            [parameter(ValueFromPipeline=$true)]
            [string] $ComputerName = $env:COMPUTERNAME,
            
            [parameter(ValueFromPipeline=$true)]
            [array] $InvSelectType,

            [parameter(ValueFromPipeline=$true)]
            [string] $LogFileName
          )    
    process{
        
        #результат - массив: (тип информации; данные (список))
        $result = @()

        #путь расположения каталога с модулями командлета в корне запуска
        $PathInvScript = "$PSScriptRoot\Get-Inventory-Module"

        #сессия удаленного подключения
        $cimSession = $null

        #дата сбора
        $collection_date = (Get-Date).ToString("dd.MM.yyyy")
            
        #если передано пустое значение - берем имя локального компьютера
        if ($ComputerName -eq "" -or !$ComputerName) {$ComputerName = $env:COMPUTERNAME}

        #локальный комьютер
        $LocalComputer = $ComputerName -eq $env:COMPUTERNAME
        
        #определяем версию PowerShell
        if ($LocalComputer)
        {
            $PSver = $PSVersionTable.PSVersion.Major
        }
        else
        {
            #проверяем наличие прав у пользователя
            $InvokeError = $null
            $PSver = Invoke-Command -Computername $ComputerName -Scriptblock {$PSVersionTable.PSVersion.Major} -ErrorAction SilentlyContinue -ErrorVariable InvokeError
            
            #если есть ошибка AccessDenied при вызове Invoke-Command значит у пользователя нет прав - прекращаем выполнение
            if ($InvokeError.FullyQualifiedErrorId -like "*AccessDenied*")
            {
                WriteLogGetInventory "Пользователь $($env:UserName) не имеет прав удаленного управления компьютером $ComputerName. Прекращаем выполнение." -WriteHost $true
                return $result
            }
        } #if ($LocalComputer)

        #если не локальный компьютер и версия PowerShell выше 2 - создаем сессию удаленого подключения к $ComputerName
        if (-not $LocalComputer -and $Psver -gt 2) {$cimSession = New-CimSession -ComputerName $ComputerName}

        #получаем скрипты инвентаризации в каталоге модулей
        $scripts = Get-ChildItem -Path $PathInvScript | Where-Object {$_.Name -like "*.ps1"}

        #если передан список имен модулей инвентаризации - выбираем только переданные имена модулей
        if ($InvSelectType) { $scripts = $scripts | Where-Object {$_.Name -in $InvSelectType} }

        #формируем функции по содержимому скриптов инвентаризации
        foreach ($script in $scripts)
        {
            #содержимое файла
            $script_content = Get-Content -Path $script.FullName | Out-String 
            #наименование функции по имени файла
            $function_name = "Get-Inv-$($script.BaseName)"
            
            <# для отладки. если функция существует - удаляем ее
               if (Test-Path -Path Function:$function_name) { [void](Remove-Item -Path function:$function_name) }
            #>

            #если функция не существует - создаем ее
            if (!(Test-Path -Path Function:$function_name)) { [void](New-Item -Path function: -Name $function_name -Value $script_content) }
           
            #вызываем созданную функцию добавляем результат в общему результату
            $result += Invoke-Expression $function_name
        }

        return $result
    }
}


<#
    Получить данные класса WMI
    в случае локального компьютера используется Get-WmiObject
    в случае удаленного компьютера, если версия PS выше 2 используется Get-CimInstance (предпочтительнее использовать т.к. есть опция -OperationTimeoutSec), иначе используется Get-WmiObject
    Параметры:
        $ComputerName - имя компьютера
        $ClassName - наименование класса WMI 
        $PSver - версия PS
        $cimSession - сессия удаленного подклчюения для Get-CimInstance
        $Namespace - по умолчанию $null
#>

function Get-WmiClass ($ComputerName, $ClassName, $PSver, $cimSession, $Namespace = $null, $Filter = $null) {

    #локальный компьютер
    $LocalComputer = $ComputerName -eq $env:COMPUTERNAME

    #ошибка выполнения
    $GetWmiError = $null

    #если локальный компьютер
    if ($LocalComputer)
    {
        #Получение данных - WMI
        $LogText = "Модуль: $CurrnetTypeInfo. Локальный сбор: Get-WmiObject -Class $ClassName -Namespace $Namespace -Filter $Filter"

        $x = Get-WmiObject -Class $ClassName -Namespace $Namespace -Filter $Filter -ErrorAction SilentlyContinue -ErrorVariable GetWmiError
    }
    else 
    {
        #если версия PowerShell больше 2 - используем Get-CimInstance
        if ($Psver -gt 2)
        {
            #Получение данных - CIM
            $LogText = "Модуль: $CurrnetTypeInfo. Удаленный сбор: версия PS $Psver, Get-CimInstance -CimSession $cimSession -ClassName $ClassName -Namespace $Namespace -Filter $Filter"

            $x = Get-CimInstance -CimSession $cimSession -ClassName $ClassName -Namespace $Namespace -Filter $Filter -OperationTimeoutSec 60 -ErrorAction SilentlyContinue -ErrorVariable GetWmiError
        } 
        else
        {
            #Получение данных PS2 - WMI
            $LogText = "Модуль: $CurrnetTypeInfo. Удаленный компьютер: версия PS $Psver, Get-WmiObject -ComputerName $ComputerName -Class $ClassName -Namespace $Namespace -Filter $Filter"

            if ($Namespace)
            {
                $x = Get-WmiObject -ComputerName $ComputerName -Class $ClassName -Namespace $Namespace -Filter $Filter -ErrorAction SilentlyContinue -ErrorVariable GetWmiError
            }
            else
            {
                $x = Get-WmiObject -ComputerName $ComputerName -Class $ClassName -Filter $Filter -ErrorAction SilentlyContinue -ErrorVariable GetWmiError
            }
        }
    }

    #записываем в лог
    WriteLogGetInventory $LogText

    #если были ошибки 
    if ($GetWmiError) { WriteLogGetInventory $GetWmiError}

    return $x
}


function WriteLogGetInventory {
    Param (
            [string]$LogText,
            [string]$LogFile = $LogFileName,
            [boolean]$WriteHost = $false
          )

    if ($WriteHost)
    {
        Write-Host $LogText
    }

    if ($LogFile -and $LogText)
    {
        $log_time = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
        Add-Content $LogFile -Value "$($log_time);$($env:COMPUTERNAME);$(Split-Path $MyInvocation.MyCommand.Name -Leaf);Модуль:$($MyInvocation.MyCommand.Name) - $LogText"
    }
}


<#
    Примеры использования командлета. 
    
    #Получить инвентаризацю с компьютера на котором запущен данный скрипт
    Get-Inventory 

    #Получить инвентаризауию с компьютера с именем "Computer"
    Get-Inventory -ComputerName "Computer"

    #Получить инветаризацию и сохранить данные в отдельные CSV файлы по типу информации
    $PathScriptRoot = $MyInvocation.MyCommand.Path | Split-Path -Parent
    $inv_res = Get-Inventory
    $inv_res | ForEach-Object {$_.Data | Export-csv -Path "$PathScriptRoot\test.$($_.Type).csv" -Encoding UTF8 -NoTypeInformation}

    #получить информацию с компьютера Computer указанных типов
    $t = "swr.ps1", "svc.ps1"
    Get-Inventory -ComputerName "Computer" -InvSelectType $t
#>
