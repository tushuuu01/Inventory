<#
    Сбор инвентаризационной информации
    Модуль сбора профилей пользователей

    Наименование типа инвентаризационой информации - не удалять!

    <Description>Профили пользователей</Description>

    Если значение LastUseTime возвращается в виде Tickets преобразуем в DateTime.
    Если значение LastUseTime возвращается в виде DateTime берем его.
#>

#получаем имя текущей функции (имя функции Get-Inv-ххх), из него тип собираемой информации
$CurrnetTypeInfo = ($MyInvocation.MyCommand.Name -split "-")[-1]

$r = $null
$r = Get-WmiClass -ComputerName $ComputerName -ClassName "Win32_UserProfile" -cimSession $cimSession -PSver $PSver

$r = $r | Where-Object {$_.lastusetime -ne $null} | Select @{Name="ComputerName"; expression={$ComputerName}},`
                                                           @{Name="UserName"; expression={([System.Security.Principal.SecurityIdentifier]$_.SID).Translate([System.Security.Principal.NTAccount]).Value}},`
                                                           localpath,`
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
                                                            },`
                                                           @{Name="CollectionDate"; Expression={$collection_date}},`
                                                           @{Name="TypeInfo"; Expression={$CurrnetTypeInfo}} | `
                                                           Sort-Object LastUseTime -Descending

if ($r) {$r = [pscustomobject]@{Type = $CurrnetTypeInfo; Data = $r}}
return $r