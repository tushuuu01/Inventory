<#
   Сбор инвентаризационной информации

   Проверка параметра InvOU
   Если параметр передан - проверяем наличие OU
   Если параметр не передан - получаем OU текущего компьютера
#>
function CheckOU {
    Param (
        [string]$InvOU,
        [array]$InvComputerList
    )

    $result = $null

    #если параметр InvOU передан проверяем существование OU
    if ($InvOU)
    {
        CheckADPowerShell

        if (!([adsi]::Exists("LDAP://$InvOU")))
        {
            WriteLog "Не найдено OU $InvOU. Прекращаем выполнение."
            break
        }
        else
        {
            $result = $InvOU
        }
    }
    #если параметры InvComputerList и InvOU не переданы - получаем текущее OU
    elseif (!$InvComputerList)
    {
        CheckADPowerShell

        $CurrentOU = (Get-ADComputer -Identity $env:COMPUTERNAME).DistinguishedName -split ","
        $result = $CurrentOU[1..$CurrentOU.Count] -join ","
        WriteLog "Параметр InvOU не задан. Будет использоваться текущее OU: $result"
    }

    return $result
}


<#
   Проверка наличия модуля ActiveDirectory для PowerShell
#>
function CheckADPowerShell {

    if (!(Get-Module -ListAvailable -Name ActiveDirectory)) 
    {
        WriteLog "Модуль Powershell для ActiveDirectory не установлен"
        Write-Host "Для установки на Windows Server выполните команды:"
        Write-Host "Get-WindowsFeature -Name 'RSAT-AD-PowerShell'"
        Write-Host "Install-WindowsFeature -Name 'RSAT-AD-PowerShell' -IncludeAllSubFeature"
        Write-Host "Прекращаем выполнение"
        break
    }
}
