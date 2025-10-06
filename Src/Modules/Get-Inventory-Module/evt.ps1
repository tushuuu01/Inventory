<#
    Сбор инвентаризационной информации
    Модуль сбора событий включения и выключения СВТ
    
    Данные получаются за последение шесть месяцев.

    Наименование типа инвентаризационой информации - не удалять!

    <Description>События включения-выключения (за 6 месяцев)</Description>
#>

#диапазон дат - полгода
$StartDate = (Get-Date).AddMonths(-6)
$EndDate = (Get-Date).AddDays(-1)

#коды выбираемые события
$IDlist = 6005,6006,1074,41,6008

#описание событий
$EventsName = @{
    6005 = "Включение"
    6006 = "Выключение"
    1074 = "Перезагрузка"
    41   = "Выключение по ошибке"
    6008 = "Аварийное выключение"
}

#получаем имя текущей функции (имя функции Get-Inv-ххх), из него тип собираемой информации
$CurrnetTypeInfo = ($MyInvocation.MyCommand.Name -split "-")[-1]

#если локальный компьютер
if ($LocalComputer) {
    $r = Get-WinEvent -FilterHashtable @{LogName='System'; StartTime=$StartDate; EndTime=$EndDate; ID=$IDlist} -ErrorAction SilentlyContinue |`
                            select @{Name="ComputerName"; expression={(($_.MachineName).Split(".")[0]).ToUpper()}}, `
                                   @{Name="EventDate"; expression={$_.TimeCreated.ToString("dd.MM.yyyy HH:mm:ss")}}, `
                                   @{Name="Event"; expression={$EventsName[$_.Id]}}, `
                                   @{Name="CollectionDate"; expression={$collection_date}}, `
                                   @{Name="TypeInfo"; Expression={$CurrnetTypeInfo}}
}
else
{
    #если удаленный компьютер
    $r = Get-WinEvent -ComputerName $ComputerName -FilterHashtable  @{LogName='System'; StartTime=$StartDate; EndTime=$EndDate; ID=$IDlist} -ErrorAction SilentlyContinue |`
                            select @{Name="ComputerName"; expression={$ComputerName}}, `
                                   @{Name="EventDate"; expression={$_.TimeCreated.ToString("dd.MM.yyyy HH:mm:ss")}}, `
                                   @{Name="Event"; expression={$EventsName[$_.Id]}}, `
                                   @{Name="CollectionDate"; expression={$collection_date}}, `
                                   @{Name="TypeInfo"; Expression={$CurrnetTypeInfo}}
}


if ($r) {$r = [pscustomobject]@{Type = $CurrnetTypeInfo; Data = $r}}
return $r