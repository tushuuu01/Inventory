<#
    Корректировка данных в CSV файлах.
    Добавление или удаление колонок.
#>


$InvAnyComputers = "C:\share\Inventory\InvAnyComputers"

#задать тип информации для изменения данных в CSV файлах
$type = "shr"

<#задать имена полей в CSV файлах:
    в случае если надо убрать поле - не ключать его в список
    если надо добавить поле - включить в список.
 #>
$column_name = "ComputerName","name","caption","path","status","Type","SharePermissions","FolderName","GroupUser","NTFSPermissions","CollectionDate","TypeInfo"

$inv_computers_list = Get-ChildItem -Path $InvAnyComputers | Where-Object {$_.Name -match '\.\w\w\w\.csv'} | `
                                                            select @{name = "ComputerName"; expression ={$_.name.Split(".")[0]}},`
                                                            @{name = "Type"; expression ={$_.name.Split(".")[1]}},`
                                                            LastWriteTime, Name, FullName, Length

$inv_type_list = $inv_computers_list | Where-Object Type -eq $type

$inv_type_list | foreach {
                            $_.FullName
                            $f = Import-Csv $_.FullName | select $column_name
                            $f | Export-Csv -Path $_.FullName -Encoding UTF8 -NoTypeInformation
                         }
