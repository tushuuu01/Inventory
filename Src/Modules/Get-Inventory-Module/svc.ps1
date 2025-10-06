<#
    ИМА Сбор инвентаризационной информации
    Модуль сбора перечная служб ОС

    Наименование типа инвентаризационой информации - не удалять!

    <Description>Службы</Description>
#>

#получаем имя текущей функции (имя функции Get-Inv-ххх), из него тип собираемой информации
$CurrnetTypeInfo = ($MyInvocation.MyCommand.Name -split "-")[-1]

$r = $null
$r = Get-WmiClass -ComputerName $ComputerName -ClassName "Win32_Service" -cimSession $cimSession -PSver $PSver

$r = $r | select @{Name="ComputerName"; expression={$ComputerName}}, `
                 Name, `
                 DisplayName, `
                 StartMode, `
                 State, `
                 StartName, `
                 @{Name="CollectionDate"; Expression={$collection_date}}, `
                 @{Name="TypeInfo"; Expression={$CurrnetTypeInfo}}

if ($r) {$r = [pscustomobject]@{Type = $CurrnetTypeInfo; Data = $r}}
return $r