<#
    Сбор инвентаризационной информации
    Модуль сбора информации о подключенных мониторах

    Наименование типа инвентаризационой информации - не удалять!

    <Description>Мониторы</Description>
#>

#получаем имя текущей функции (имя функции Get-Inv-ххх), из него тип собираемой информации
$CurrnetTypeInfo = ($MyInvocation.MyCommand.Name -split "-")[-1]

$r = $null

$r = Get-WmiClass -ComputerName $ComputerName -ClassName "WmiMonitorID" -Namespace "root\wmi" -cimSession $cimSession -PSver $PSver
$r = $r | Select @{Name="ComputerName"; expression={$ComputerName}}, `
                 @{Name = "ManufacturerName"; expression = {[System.Text.Encoding]::ASCII.GetString($_.ManufacturerName -notmatch "^0$")}}, `
                 @{Name = "MonitorName"; expression = {[System.Text.Encoding]::ASCII.GetString($_.UserFriendlyName -notmatch "^0$")}}, `
                 @{Name = "SerialNumber"; expression = {[System.Text.Encoding]::ASCII.GetString($_.SerialNumberID -notmatch "^0$")}},`
                 WeekOfManufacture, `
                 YearOfManufacture, `
                 @{Name="CollectionDate"; Expression={$collection_date}}, `
                 @{Name="TypeInfo"; Expression={$CurrnetTypeInfo}}

if ($r) {$r = [pscustomobject]@{Type = $CurrnetTypeInfo; Data = $r}}
return $r
