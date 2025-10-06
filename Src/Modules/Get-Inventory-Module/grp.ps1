<#
    Сбор инвентаризационной информации
    Модуль сбора состава локальных групп

    Наименование типа инвентаризационой информации - не удалять!

    <Description>Состав локальных групп</Description>
#>

#получаем имя текущей функции (имя функции Get-Inv-ххх), из него тип собираемой информации
$CurrnetTypeInfo = ($MyInvocation.MyCommand.Name -split "-")[-1]

#получаем перчень локальных групп
$gropus = Get-WmiClass -ComputerName $ComputerName -ClassName "win32_group" -Filter "LocalAccount='True'" -cimSession $cimSession -PSver $PSver

$r = @()

$ErrorMessage = ""

#цикл по локальных группам
foreach ($group in $gropus) {
    
    $UsersNotFound = ""

    #получаем членов локальной группы
    try {
        $g = [ADSI]"WinNT://$ComputerName/$($group.Name)"
        $members = @($g.psbase.Invoke("Members"))


        #цикл по членам группы
        $members | foreach {
            #формируем строку группа - состав
            $result = "" | select ComputerName, GroupName, UserName, Type, Domain, CollectionDate, TypeInfo
            $result.ComputerName = $ComputerName
            $result.GroupName = $group.Name

            $result.UserName = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
            $result.Type = $_.GetType().InvokeMember("Class", 'GetProperty', $null, $_, $null)

            $ADsPath = ($_.GetType().InvokeMember("ADsPath", 'GetProperty', $null, $_, $null)).Replace("WinNT://", "")

            #если локальная группа\уз
            if ($ADsPath -like "*/$ComputerName/*") {
                $ADsPath = ""
            }

            $result.Domain = $ADsPath

            $result.CollectionDate = $collection_date
            $result.TypeInfo = $CurrnetTypeInfo

            $r += $result
        } #foreach
    } #try
    catch
    {
        #если ну удалось получить состав группы опредялем переменную
        $UsersNotFound = "Состав группы не определен"

        $ErrorMessage = $_
    }
    finally
    {
        #если произошла ошибка при получении состава группы или
        #если членов группы нет - добавляем пустую строку с именем группы
        if ($members.Count -eq 0)
        {
            $result = "" | select ComputerName, GroupName, UserName, Type, Domain, CollectionDate, TypeInfo
            $result.ComputerName = $ComputerName
            $result.GroupName = $group.Name
            $result.CollectionDate = $collection_date
            $result.UserName = $UsersNotFound
            $result.TypeInfo = "grp"
            $r += $result
        }
    } #finally
} #foreach

if ($ErrorMessage) { WriteLogGetInventory "$CurrnetTypeInfo - Не удается подключиться к $ComputerName с использованием [ADSI]. Ошибка: $ErrorMessage" -WriteHost $true }

if ($r) {$r = [pscustomobject]@{Type = $CurrnetTypeInfo; Data = $r}}
return $r
