<#
    Модуль обновления данных в отчете - файл inv.xlsm

    Для автоматического обновления данных.
    Предварительно необходимо открыть файл inv.xlsm на том компьютере и под тем пользователем, под которорым в дальнейшем будет выполняться скрипт,
    и запустить процедуру обновления кнопкой "Обновить все" на листе "Общее" либо кнопкой в меню Данные.
    При обновлении, если потребуется, выбрать уровень конфиденциальности, при дальнейшем обновлении окно с выбором уровня появляться не должно.

    Скрипт открывает файл, выполняет метод RefreshAll(), ожидает 180 секунд (время требуемое для обновления), вносить информацию о дате и времени обновления, 
    сохраняет и закрывает файл.

    От системы запустить не удалось - не удается интерактивно выбрать уровень конфиденциальности.

    Новгородов Павел 11.2024
#>


$ExcelFile = "C:\SHARE\Inventory\Report\inv.xlsm"

#если файл открыт - закрываем
$fileid = Get-SmbOpenFile | Where-Object Path -like "*$(Split-Path -Path $ExcelFile -Leaf)" | select FileId
$fileid | Close-SmbOpenFile -Force

$xl = New-Object -ComObject Excel.Application
$xl.Visible = $true

$wb = $xl.Workbooks.Open($ExcelFile)

$wb.Queries.FastCombine = $true

$wb.RefreshAll()

Start-Sleep -Seconds 180

$d = Get-Date -Format "dd.MM.yyyy HH:mm"
$wb.Sheets.Item("Общее").Cells.Item(17,1).Value2 = "Обновление данных выполнено: $d"
$wb.Sheets.Item("Компьютеры").Select()

$wb.Save()
$wb.Close()
$xl.Quit() 
Get-Process -Name "*excel*" | Where-Object {$_.MainWindowHandle -eq $xl.Hwnd} | Stop-Process