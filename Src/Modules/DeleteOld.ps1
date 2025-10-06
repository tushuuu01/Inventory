<#
    Сбор инвентаризационной информации
    Модуль удаления старых файлов инвентаризации

    В каталоге InvAnyComputers удаляются файлы старше DayToDelete дней
#>

Function DeleteOld {
    Param(
        [string]$InvAnyComputers,
        [int]$DayToDelete
    )

    #удаляем только в случае если $DayToDelete больше одного дня - чтобы случайно все не удалить
    if ($DayToDelete -gt 1)
    {

        $DateOld = (Get-Date).AddDays(-$DayToDelete)

        WriteLog "Будет выполнено удаление файлов инвентаризации старше $($DateOld.ToString("dd-MM-yyyy")) ($DayToDelete дней)"

        $FilesOld = Get-ChildItem -Path $InvAnyComputers | Where-Object {$_.CreationTime -lt $DateOld -and {$_.Name -match '\w\.\w\w\w\.csv'}}

        WriteLog "Количество файлов для удаления $($FilesOld.Count)"

        $FilesOld | Remove-Item

        if ($FilesOld.Count -gt 0) {WriteLog "Удаление старых файлов инвентаризации выполнено"}
    }
}