<#
    Сбор инвентаризационной информации
    Модуль сбора установленных обновлений ОС

    Наименование типа инвентаризационой информации - не удалять!

    <Description>Обновления ОС</Description>
#>

#получаем имя текущей функции (имя функции Get-Inv-ххх), из него тип собираемой информации
$CurrnetTypeInfo = ($MyInvocation.MyCommand.Name -split "-")[-1]

$r = $null
if ($LocalComputer)
    {$r = Get-HotFix}
    else
    {$r = Get-HotFix -ComputerName $ComputerName }  

$r = $r | select @{Name="ComputerName"; expression={$ComputerName}}, `
                 Description, `
                 HotFixID, `
                 InstalledBy, `
                 @{Name="InstalledOn"; expression={$_.InstalledOn.ToString("dd.MM.yyyy")}}, `
                 @{Name="CollectionDate"; Expression={$collection_date}}, `
                 @{Name="TypeInfo"; Expression={$CurrnetTypeInfo}}

if ($r) {$r = [pscustomobject]@{Type = $CurrnetTypeInfo; Data = $r}}
return $r