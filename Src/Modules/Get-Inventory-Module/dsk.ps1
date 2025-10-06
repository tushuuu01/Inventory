<#
    Сбор инвентаризационной информации
    Модуль сбора логических дисков

    Наименование типа инвентаризационой информации - не удалять!

    <Description>Логические разделы</Description>
#>

#получаем имя текущей функции (имя функции Get-Inv-ххх), из него тип собираемой информации
$CurrnetTypeInfo = ($MyInvocation.MyCommand.Name -split "-")[-1]


$r = $null
$r = Get-WmiClass -ComputerName $ComputerName -ClassName "Win32_LogicalDisk" -cimSession $cimSession -PSver $PSver
$r = $r | Where-Object {$_.DriveType -eq 3} 

$r = $r | select @{Name="ComputerName"; Expression={$ComputerName}}, `
                 DeviceID, `
                 FileSystem, `
                 @{Name="Size";Expression={($_.Size/1GB).tostring("F00")}}, `
                 @{Name="FreeSpace"; Expression={($_.FreeSpace/1GB).tostring("F00")}}, `
                 @{Name="CollectionDate"; Expression={$collection_date}}, `
                 @{Name="TypeInfo"; Expression={$CurrnetTypeInfo}}

if ($r) {$r = [pscustomobject]@{Type = $CurrnetTypeInfo; Data = $r}}
return $r