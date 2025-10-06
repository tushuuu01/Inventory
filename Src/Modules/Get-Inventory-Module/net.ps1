<#
    Сбор инвентаризационной информации
    Модуль сбора информации по сетевым интерфейсам

    Наименование типа инвентаризационой информации - не удалять!

    <Description>Сетевые карты</Description>
#>

#получаем имя текущей функции (имя функции Get-Inv-ххх), из него тип собираемой информации
$CurrnetTypeInfo = ($MyInvocation.MyCommand.Name -split "-")[-1]

$r = $null
$r = Get-WmiClass -ComputerName $ComputerName -ClassName "Win32_NetworkAdapterConfiguration" -cimSession $cimSession -PSver $PSver

$r = $r | Where-Object {($_.IPEnabled -eq $true)} | select @{Name="ComputerName"; expression={$ComputerName}}, Description, `
                                                           @{Name = "IPAddress"; expression={$_.IPAddress -join ";"}}, `
                                                           @{Name = "IPSubnet"; expression={$_.IPSubnet -join ";"}}, `
                                                           @{Name = "DefaultIPGateway"; expression={$_.DefaultIPGateway -join ";"}}, `
                                                           @{Name = "DNSServer"; expression={$_.DNSServerSearchOrder -join ";"}}, `
                                                           DHCPEnabled, `
                                                           DHCPServer, `
                                                           MACAddress, `
                                                           @{Name="CollectionDate"; Expression={$collection_date}}, `
                                                           @{Name="TypeInfo"; Expression={$CurrnetTypeInfo}}

if ($r) {$r = [pscustomobject]@{Type = $CurrnetTypeInfo; Data = $r}}
return $r