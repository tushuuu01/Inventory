<#
    Сбор инвентаризационной информации
    Модуль сбора подключенных сетевых дисков.

    Наименование типа инвентаризационой информации - не удалять!

    <Description>Сетевые диски</Description>

    
    Подключеные диски определяются из пользовательского ключа реестра.

    Подключенные диски получаются для доменных пользователей работавших на компьютере не позже месяца.
    Последовательность:
    1. Получение профилей пользователей на компьютере, выбор доменных пользователей работавших на компьютере не позже месяца.
       Определяется дата последнего использования профиля LastUseTime.
       Если значение LastUseTime возвращается в виде Tickets преобразуем в DateTime.
       Если значение LastUseTime возвращается в виде DateTime берем его.
    2. Для таких пользователей получение раздела реестра для SID пользователей.
    3. Получение подключенных сетевых дисков.

#>

#получаем имя текущей функции (имя функции Get-Inv-ххх), из него тип собираемой информации
$CurrnetTypeInfo = ($MyInvocation.MyCommand.Name -split "-")[-1]

$r = @()

#дата последнего использования профиля пользователем
$LastDateUseProfile = (Get-Date).AddMonths(-1)

#профили пользователей на компьютере
$UsersProfile = Get-WmiClass -ComputerName $ComputerName -ClassName "Win32_UserProfile" -cimSession $cimSession -PSver $PSver

$UsersProfile = $UsersProfile | Where-Object {$_.lastusetime -ne $null} |`
                                Select SID, `
                                       @{Name="UserName"; expression={([System.Security.Principal.SecurityIdentifier]$_.SID).Translate([System.Security.Principal.NTAccount]).Value}},`
                                       @{Name="LastUseTime"; Expression={
                                                                            if ($_.lastusetime.length -eq 1)
                                                                            {
                                                                                $_.lastusetime
                                                                            }
                                                                            else
                                                                            {
                                                                                $_.ConvertToDateTime($_.lastusetime)
                                                                            }
                                                                         }
                                        } | Where-Object -FilterScript {$_.UserName -Like "$env:USERDOMAIN*" -and $_.LastUseTime -gt $LastDateUseProfile}

#локальный компьютер
$LocalComputer = $ComputerName -eq $env:COMPUTERNAME

#цикл по пользователям
foreach($user in $UsersProfile) {
    
    #получаем содержимое ключа HKEY_USERS\$($user.SID)\Network\, предварительно проверяем наличие указанного ключа
    if ($LocalComputer) {
            #локальный компьютер
            if (Test-Path "Registry::HKEY_USERS\$($user.SID)\Network\")
            {
                $drives = Get-ChildItem "Registry::HKEY_USERS\$($user.SID)\Network\" | Get-ItemProperty | select PSChildName, RemotePath

            }
    }
    else
    {
                #удаленный компьютер
                $drives = Invoke-Command -ComputerName $ComputerName -ScriptBlock { 
                                                                                        if (Test-Path "Registry::HKEY_USERS\$($Using:user.SID)\Network\")
                                                                                        {
                                                                                                Get-ChildItem "Registry::HKEY_USERS\$($Using:user.SID)\Network\" | Get-ItemProperty | select PSChildName, RemotePath
                                                                                        }
                                                                                  }
    }

        $r += $drives | select @{Name="ComputerName"; expression={$ComputerName}},`
                               @{Name="UserName"; expression={$user.UserName}},`
                               @{Name="MapDrive"; expression={$_.PSChildName.ToUpper()}},`
                               @{Name="Path"; expression={$_.RemotePath}},`
                               @{Name="CollectionDate"; expression={$collection_date}},`
                               @{Name="TypeInfo"; expression={$CurrnetTypeInfo}}
}

if ($r) {$r = [pscustomobject]@{Type = $CurrnetTypeInfo; Data = $r}}
return $r
