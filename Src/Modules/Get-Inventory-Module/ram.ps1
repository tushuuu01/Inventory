<#
    Сбор инвентаризационной информации
    Модуль сбора модули памяти

    Наименование типа инвентаризационой информации - не удалять!

    <Description>Память</Description>
#>

$MemTypeName = @{
                    "0" = "Unknown";
                    "1" = "Other";
                    "2" = "DRAM";
                    "4" = "Cache DRAM";
                    "5" = "EDO";
                    "6" = "EDRAM";
                    "7" = "VRAM";
                    "8" = "SRAM";
                    "9" = "RAM";
                    "10" = "ROM";
                    "11" = "Flash";
                    "12" = "EEPROM";
                    "13" = "FEPROM";
                    "14" = "EPROM";
                    "15" = "CDRAM";
                    "16" = "3DRAM";
                    "17" = "SDRAM";
                    "18" = "SGRAM";
                    "19" = "RDRAM";
                    "20" = "DDR";
                    "21" = "DDR-2";
                    "22" = "DDR2 FB-DIMM";
                    "24" = "DDR3";
                    "25" = "FBD2";
                    "26" = "DDR4";
}

#получаем имя текущей функции (имя функции Get-Inv-ххх), из него тип собираемой информации
$CurrnetTypeInfo = ($MyInvocation.MyCommand.Name -split "-")[-1]

$r = $null
$r = Get-WmiClass -ComputerName $ComputerName -ClassName "Win32_Physicalmemory" -cimSession $cimSession -PSver $PSver

$r = $r | select @{Name="ComputerName"; Expression={$ComputerName}}, `
                 @{Name="Capacity"; Expression={($_.capacity/1MB).tostring("F00")}}, `
                 @{Name="DeviceLocator"; Expression={$_.DeviceLocator}}, `
                 @{Name="MemoryType"; Expression={$MemTypeName[$_.MemoryType.ToString()]}}, `
                 @{Name="CollectionDate"; Expression={$collection_date}}, `
                 @{Name="TypeInfo"; Expression={$CurrnetTypeInfo}}

if ($r) {$r = [pscustomobject]@{Type = $CurrnetTypeInfo; Data = $r}}
return $r