<#
    Очистка CSV файлов
#>

$InvResult = "C:\Inventory\InvResult"

function ClearCSV {
    Param (
            [Parameter(ValueFromPipeline = $true)]
            [string]$FileName
    )
    
    $FileName

    $s = Import-Csv $FileName
    $columns = $s[0].psobject.Properties.name

    [array] | select $columns | Export-Csv -Path $FileName -Encoding UTF8 -NoTypeInformation

}

            
#путь запуска скрипта
$PathScriptRoot = $MyInvocation.MyCommand.Path | Split-Path -Parent

$CsvFiles = Get-ChildItem -Path $InvResult | Where-Object {$_.Name -like "*.csv"} | select FullName

$CsvFiles.FullName | foreach {ClearCSV -FileName $_}
