<# 
    Запись в лог файл.
    Передатеся параметр $LogText - текст сообщения.
    Используются глобальные переменные:
        $InvLogFile - имя лог файла
    Формат лог файла:
        Дата время; Имя компьютера; Имя скрипта; Текст
#>
function WriteLog {
    Param (
            [string]$LogText,

            #если WriteHost = $true - выдавать сообщение на консоль
            [boolean]$WriteHost = $true
    )

    if ($WriteHost)
    {
        Write-Host $LogText
    }

    if ($global:InvLogFile)
    {
        $log_time = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
        Add-Content $global:InvLogFile -Value "$($log_time);$($env:COMPUTERNAME);$(Split-Path $MyInvocation.ScriptName -Leaf);$LogText"
    }
}
