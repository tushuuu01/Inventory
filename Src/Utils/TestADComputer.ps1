<#
    Модуль проверки доступности компьютеров по сети для управления по WinRM в OU.

    Требуется установка модуля ActiveDirectory для Powershell.

    Параметр -InvOU - OU в домене содержащем компьютеры для опроса.

    Возможно удаленное включение службы WinRM - выделить в Out-GridView требуемые компьютеры и нажать OK.

    Новгородов Павел 07.2024
#>


function Get-ComputerStatus {
    [cmdletbinding()]
    Param(
        [parameter(ValueFromPipeline=$True)]
        [string]
        $InvOU = ""
        )
    process {

    $answer = $null
    while ($answer -ne "ДА" -and $answer -ne "НЕТ") {
        $answer = (Read-Host "Будет выполнен опрос компьютеров из OU $InvOU. При необходимости скорректируйте значение данного параметра. Запустить опрос - Да\Нет ?").ToUpper()
    }

    if ($answer -ne "ДА")
    {
        break
    }


    $answer = $null
    while ($answer -ne "ДА" -and $answer -ne "НЕТ") {
        $answer = (Read-Host "Получить выборку компьютеров доступных по сети и не доступных через WinRM - Да\Нет ?").ToUpper()
    }

    #импортировать модули
    Import-Module $PSScriptRoot\Get-ComputerStatus.ps1 -Force

    #получаем перечень компьютеров в OU
    "Получаем перечень компьютеров в $InvOU и определяем доступность"
    $computer_list = Get-ComputerStatus -OUName $InvOU | select ComputerName, ComputerOS, ComputerDescription, NetAccess, PSAccess, ComputerOU

    #если выбрано отображать только доступные по сети компьютеры - отбираем такие
    if ($answer -eq "ДА")
    {
        $computer_list = $computer_list | Where-Object {$_.NetAccess -and (-not $_.PSAccess)}

        $computer_winrm = $computer_list | Out-GridView -Title "Выберите из списка компьютеры на которых требуется настроить службу WinRM" -PassThru 
    
        #если были выбраны компьютеры из списка - включаем для них службу WinRM
        if ($computer_winrm)
        {
            foreach ($c in $computer_winrm)
            {
                "Выполняем настройку службы на комьютере $($c.ComputerName)"
                
                & c:\Windows\System32\sc.exe \\$($c.ComputerName) config WinRM start=auto
                & c:\Windows\System32\sc.exe \\$($c.ComputerName) start WinRM

                #Invoke-Command -ComputerName $c.ComputerName -ScriptBlock {winrm quickconfig}
            }
        }
    }
    else
    {
        $computer_list | Out-GridView
    }

    } #process
} #function


Get-ComputerStatus -InvOU "OU=Kurgan,DC=region,DC=cbr,DC=ru"