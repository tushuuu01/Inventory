<#
    Модуль проверки удаленного сбора инвентаризации

    Будет запрошено имя компьютера для удаленного сбора

    Новгородов Павел 07.2024
#>

$ComputerName = Read-host "Введите имя компьютера"

if ($ComputerName) {
    if (-not (Test-Connection -Count 1 -ComputerName $ComputerName -Quiet)) {
        "Компьютер $ComputerName не доступен по сети!"   
        break
    }
}

"Будет собрана инвентаризация с компьютера: $ComputerName"

#импортировать модули
Import-Module ..\Function\Get-Inventory.ps1 -Force

#получить данные инвентаризации
"Получаем инвентаризацию"
$inv_res = Get-Inventory -ComputerName $ComputerName
$inv_res | Out-GridView