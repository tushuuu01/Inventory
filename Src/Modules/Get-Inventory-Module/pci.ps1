<#
    Сбор инвентаризационной информации
    Модуль PCI устройств

    Наименование типа инвентаризационой информации - не удалять!

    <Description>PCI устройства</Description>
#>

#получаем имя текущей функции (имя функции Get-Inv-ххх), из него тип собираемой информации
$CurrnetTypeInfo = ($MyInvocation.MyCommand.Name -split "-")[-1]

$r = $null

$r = Get-WmiClass -ComputerName $ComputerName -ClassName "Win32_PNPEntity" -cimSession $cimSession -PSver $PSver

$r = $r |  Where-Object {$_.DeviceID -like "PCI*"} | `
           select @{Name="ComputerName"; Expression={$ComputerName}},`
                  Name,`
                  Manufacturer,`
                  DeviceID,`
                  Service,`
                  @{Name="CollectionDate"; Expression={$collection_date}},`
                  @{Name="TypeInfo"; Expression={$CurrnetTypeInfo}}

if ($r) {$r = [pscustomobject]@{Type = $CurrnetTypeInfo; Data = $r}}
return $r