<#
    Сбор инвентаризационной информации
    Модуль сбора информации о локальных пользователях

    Наименование типа инвентаризационой информации - не удалять!

    <Description>Локальные пользователи</Description>
#>

#получаем имя текущей функции (имя функции Get-Inv-ххх), из него тип собираемой информации
$CurrnetTypeInfo = ($MyInvocation.MyCommand.Name -split "-")[-1]

$local_users = Get-WmiClass -ComputerName $ComputerName -ClassName "Win32_UserAccount" -Filter "LocalAccount = $true" -cimSession $cimSession -PSver $PSver | `
               select Name, Description, Status, Disabled, Lockout, PasswordRequired, PasswordChangeable, Domain

$r = @()

$error.Clear()

foreach ($user in $local_users)
{
    #определяем парамеры УЗ
    try {
        $u = [ADSI]"WinNT://$($ComputerName)/$($user.Name), user"

        $LastLogin = $u.LastLogin[0]
        $MaxPasswordAge = $u.MaxPasswordAge[0]
        $PasswordAge = $u.PasswordAge[0]
    
        if ($LastLogin)
        {
            if ($LastLogin.GetType().Name -eq [datetime])
            {
                $LastLogin = ([datetime]$LastLogin).ToString("dd.MM.yyyy")
            }
            else
            {
                $LastLogin = $null
            }
        }

    }
    catch
    {
    }
    
    $r += New-Object psobject -Property @{
                            "ComputerName" = $ComputerName
                            "LoginName" =$user.Name
                            "Description" = $user.Description
                            "Status" = $user.Status
                            "Disabled" = $user.Disabled
                            "Lockout" = $user.Lockout
                            "PasswordRequired" = $user.PasswordRequired
                            "PasswordChangeable" = $user.PasswordChangeable
                            "LastLogin" = $LastLogin
                            "PasswordLastSet" = (Get-Date).AddSeconds(-$PasswordAge).ToString("dd.MM.yyyy")
                            "PasswordExpires" = (Get-Date).AddSeconds($MaxPasswordAge - $PasswordAge).ToString("dd.MM.yyyy")
                            "MaxPasswordAge" = [Math]::Round($MaxPasswordAge/86400)
                            "PasswordAge" = [Math]::Round($PasswordAge/86400)
                            "CollectionDate" = $collection_date
                            "TypeInfo" = $CurrnetTypeInfo
    }
} #foreach

if ($error) { WriteLogGetInventory "$CurrnetTypeInfo - Не удается подключиться к $ComputerName с использованием [ADSI]" -WriteHost $true }

$r = $r | select ComputerName, LoginName, Description, Status, Disabled, Lockout, PasswordRequired, PasswordChangeable, LastLogin, PasswordLastSet, PasswordExpires, MaxPasswordAge, PasswordAge, CollectionDate,TypeInfo

if ($r) {$r = [pscustomobject]@{Type = $CurrnetTypeInfo ; Data = $r}}
return $r