<#
    Сбор инвентаризационной информации
    Модуль сбора графических адаптеров

    Наименование типа инвентаризационой информации - не удалять!

    <Description>Графический адаптер</Description>
#>

#получаем имя текущей функции (имя функции Get-Inv-ххх), из него тип собираемой информации
$CurrnetTypeInfo = ($MyInvocation.MyCommand.Name -split "-")[-1]

$r = $null
$r = Get-WmiClass -ComputerName $ComputerName -ClassName "Win32_videoController" -cimSession $cimSession -PSver $PSver

$r = $r | Where-Object {$_.Name -NotLike "*Citrix*"} | select @{Name="ComputerName"; Expression={$ComputerName}}, `
                                                              name, `
                                                              @{Name="AdapterRamMB";Expression={($_.AdapterRAM/1MB).tostring("F00")}}, `
                                                              VideoProcessor, `
                                                              CurrentHorizontalResolution, `
                                                              CurrentVerticalResolution, `
                                                              @{Name="CollectionDate"; Expression={$collection_date}}, `
                                                              @{Name="TypeInfo"; Expression={$CurrnetTypeInfo}}

if ($r) {$r = [pscustomobject]@{Type = $CurrnetTypeInfo; Data = $r}}
return $r