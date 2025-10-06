<#
    Сбор инвентаризационной информации
    Формирование справочника типов инветаризации

    Формируется хэш таблица на основе модулей командлета Get-Inventory в каталоге Get-Inventory-Module.
    Из текста модуля выделяется наименование инвентаризационной информации расположенное между тэгами  <Description>Наименование</Description>.
    Имя модуля - код инвентаризационной информации.
#>

#путь расположения каталога с модулями командлета Get-Inventory
$PathInvScript = "$PSScriptRoot\Get-Inventory-Module"

$global:InvType = @{}

#получаем скрипты инвентаризации в каталоге модулей
$InvModules = Get-ChildItem -Path $PathInvScript | Where-Object {$_.Name -like "*.ps1"}

foreach ($InvModule in $InvModules)
{
    $TextModule = Get-Content -Path $InvModule.FullName | Out-String 

    #определяем наименование из текста модуля
    if ($TextModule -match "<Description>(.*?)</Description>") 
    {
        $global:InvType.Add($InvModule.BaseName, $Matches[1])
    }
}


