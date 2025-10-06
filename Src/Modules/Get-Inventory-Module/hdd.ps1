<#
    Сбор инвентаризационной информации
    Модуль сбора физических дисков

    Наименование типа инвентаризационой информации - не удалять!

    <Description>Жесткие диски</Description>
#>

#получаем имя текущей функции (имя функции Get-Inv-ххх), из него тип собираемой информации
$CurrnetTypeInfo = ($MyInvocation.MyCommand.Name -split "-")[-1]

$r = $null

#локальный компьютер
$LocalComputer = $ComputerName -eq $env:COMPUTERNAME

#если версия PowerShell выше 2 используем командлет Get-PhysicalDisk
if ($Psver -gt 2) {

    $LogText = "Модуль: $CurrnetTypeInfo. Вызов Get-PhysicalDisk"
    WriteLogGetInventory $LogText

    if ($LocalComputer) {$r = Get-PhysicalDisk} else {$r = Get-PhysicalDisk -CimSession $cimSession}

    $r = $r | select @{Name="ComputerName"; Expression={$ComputerName}}, `
                     @{Name="Model"; expression={($_.Manufacturer + " " + $_.Model).Trim()}}, `
                     @{Name="Size"; Expression={($_.Size/1GB).tostring("F00")}}, `
                     @{Name = "SerialNumber"; Expression={$_.SerialNumber.Trim()}}, `
                     @{Name="interfacetype"; Expression={$_.BusType}},`
                     MediaType,`
                     @{Name="CollectionDate"; Expression={$collection_date}}, `
                     @{Name="TypeInfo"; Expression={$CurrnetTypeInfo}}

    #WriteLogGetInventory "Результат: $r"
}

#если версии PS <= 2 или на предыдущем шаге не была получена информация по дискам
if ($Psver -le 2 -or $r -eq $null) 
{
        $r = Get-WmiClass -ComputerName $ComputerName -ClassName "Win32_DiskDrive" -cimSession $cimSession -PSver $PSver
        $r = $r | select @{Name="ComputerName"; Expression={$ComputerName}}, `
                         Model, `
                         @{Name="Size"; Expression={($_.Size/1GB).tostring("F00")}}, `
                         @{Name = "SerialNumber"; Expression={$_.SerialNumber.Trim()}}, 
                         interfacetype, `
                         @{Name="MediaType"; expression={""}}, 
                         @{Name="CollectionDate"; Expression={$collection_date}}, `
                         @{Name="TypeInfo"; Expression={$CurrnetTypeInfo}}

    WriteLogGetInventory "Модуль: $CurrnetTypeInfo. Вызов Get-WmiClass Win32_DiskDrive"
}

if ($r) {$r = [pscustomobject]@{Type = $CurrnetTypeInfo; Data = $r}}
return $r