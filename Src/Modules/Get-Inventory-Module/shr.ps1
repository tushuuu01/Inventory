<#
    Сбор инвентаризационной информации
    Модуль сбора информации по общим ресурсам

    Наименование типа инвентаризационой информации - не удалять!

    <Description>Общие ресурсы</Description>
#>

<#
    Модуль использует функцию Get-FolderAccess (файл \Function\Get-FolderAccess.ps1)

    Настройка модуля
        Параметр $DepthChildFolder
            $DepthChildFolder = -1 - Не получать NTFS разрешения для каталогов общих ресурсов
            $DepthChildFolder = 0  - Получить NTFS разрешения для каталогов общих ресурсов без вложенных каталогов
            $DepthChildFolder = 1  - Получить NTFS разрешения для каталогов общих ресурсов и вложенных каталогов первого уровня
            $DepthChildFolder = 2  - Получить NTFS разрешения для каталогов общих ресурсов и вложенных каталогов второго уровня, и тд

        Параметр $DepthAnyComputer - массив с перечнем компьютеров с уровнем вложенности.
        Позволяет задавает индивидуальный уровен вложенности для получения NTFS разрешений для конкретного компьютера.
        Возможно задавать имя компьютера с использованием маски.
        Например, 
            ("fs03", 3), ("fs04", 4) - определить уровень вложенности для указанных компьютеров
            или
            ("fs*", 3) - определить уровень вложенности для компьютеров с именами по маске

        Если компьютер перечислен в нескольких значениях (в том числе по маске) - будет использоваться последнее.
#>

#получаем значение параметра DepthChildFolder, если передан дополнительный параметр для модуля shr
$DepthChildFolder = ($global:MParameters | Where-Object {$_["Module"] -eq "shr" -and $_["VarName"] -eq "DepthChildFolder"}).VarValue

#если значение не получено - присваиваем 0
if (!$DepthChildFolder) {$DepthChildFolder = 0}

#получаем значение параметра DepthAnyComputer, если передан дополнительный параметр для модуля shr
$DepthAnyComputer = ($global:MParameters | Where-Object {$_["Module"] -eq "shr" -and $_["VarName"] -eq "DepthAnyComputer"}).VarValue

#если значение получено
if ($DepthAnyComputer)
{
    #получаем параметр вложенности для $ComputerName, если он перечислен в параметре 
    $DepthThisComputer = ($DepthAnyComputer | Where-Object {$ComputerName.ToUpper() -like $_[0].ToUpper()})

    #если получили параметр для $ComputerName присваем его переменной $DepthChildFolder
    if ($DepthThisComputer) {
        
        #если для $ComputerName получено более одного параметра, берем последний
        if ($DepthThisComputer[0].Count -gt 1)
        {
            $DepthChildFolder = $DepthThisComputer[($DepthThisComputer[0].Count-1)][1]
        }
        else
        {
            $DepthChildFolder = $DepthThisComputer[1]
        }

        if (Test-Path "function:WriteLog") { WriteLog "Для $ComputerName получено значение параметра DepthChildFolder = $DepthChildFolder модуля shr." }
    }
}

$ShareType = @{"0" ="Диск";
               "1" = "Очередь печати";
               "2" = "Устройство";
               "3" = "IPC";
               "2147483648" = "Администратор диска";
               "2147483649" = "Администратор очереди печати";
               "2147483650" = "Администратор устройства";
               "2147483651" = "IPC Администратор";
}

$AccessMaskType = @{
                    "2032127" =  "FullControl";
                    "1245631" = "Change";
                    "1179817" = "Read";
}
                                             
#получаем имя текущей функции (имя функции Get-Inv-ххх), из него тип собираемой информации
$CurrnetTypeInfo = ($MyInvocation.MyCommand.Name -split "-")[-1]

#получаем перечень шар
$shares = Get-WmiClass -ComputerName $ComputerName -ClassName "win32_share" -cimSession $cimSession -PSver $PSver

#локальный компьютер
$LocalComputer = $ComputerName -eq $env:COMPUTERNAME

$r = @()

foreach($share in $shares)
{
    #получаем права на шары

    #если версия PowerShell выше 4 используем командлет Get-SmbShareAccess
    if ($Psver -gt 4)
    {
        $security = Get-SmbShareAccess -Name $share.name -CimSession $cimSession | select AccountName, AccessControlType, AccessRight
        $SecurityString = ($security | foreach {"$($_.AccountName):$($_.AccessControlType)-$($_.AccessRight)"}) -join "; "
    }
    else
    #если версия PowerShell 4 или ниже используем Get-WmiObject
    {
        $ShareSecurity = Get-WmiObject -ClassName "Win32_LogicalShareSecuritySetting" -ComputerName $ComputerName -Filter "Name='$($share.name)'"

        $SecurityString = ""

        if ($ShareSecurity)
        {
            $security = $ShareSecurity.GetSecurityDescriptor().Descriptor.DACL | select @{Name = "AccountName"; expression = {([System.Security.Principal.SecurityIdentifier]$($_.Trustee.SIDString)).Translate([System.Security.Principal.NTAccount]).Value}},`
                                                                                        @{Name = "AccessRight"; expression = {$AccessMaskType[$_.AccessMask.ToString()]}}
            $SecurityString = ($security | foreach {"$($_.AccountName):$($_.AccessRight)"}) -join "; "
        }
    }

    $FolderAccess = $null

    #если у шары есть параметр path и параметра $DepthChildFolder больше -1, определяем разрешения NTFS для каталогов
    if ($share.path -and $DepthChildFolder -gt -1)
    {
        #получаем набор разрешений для каталога $share.path
        #если локальный компьютер
        if ($LocalComputer)
        {
            $FolderAccess = Get-FolderAccess -Folder $share.path -Depth $DepthChildFolder
        }
        else
        {
            $FolderAccess = Get-FolderAccess -Folder "\\$ComputerName\$($share.name)" -Depth $DepthChildFolder
        }

    }

    #формируем результат
    if ($FolderAccess) 
    {
        #формируем результат на основе списка разрешений, добавляя к каждой строке разрешений значения шары
        $r += $FolderAccess | select @{Name = "ComputerName"; expression={$ComputerName}},`
                                     @{Name = "name"; expression = {$share.Name}},`
                                     @{Name = "caption"; expression = {$share.Caption}},`
                                     @{Name = "path"; expression = {$share.Path}},`
                                     @{Name = "status"; expression = {$share.Status}},`
                                     @{Name = "Type"; Expression={$ShareType[$_.type.ToString()]}},`
                                     @{Name = "SharePermissions"; expression = {$SecurityString}}, `
                                     FolderName,`
                                     GroupUser,`
                                     NTFSPermissions,`
                                     @{Name = "CollectionDate"; Expression={$collection_date}},`
                                     @{Name = "TypeInfo"; Expression={$CurrnetTypeInfo}}
    }
    else
    {
        #формируем результат в виде одной строки по шаре если разрешения не получены
        $r += New-Object psobject -Property @{
                                              "ComputerName" = $ComputerName
                                              "name" = $share.name
                                              "caption" = $share.caption
                                              "path" = $share.path
                                              "status" = $share.status
                                              "Type" = $ShareType[$share.Type.ToString()]
                                              "SharePermissions" = $SecurityString
                                              "FolderName" = ""
                                              "GroupUser" = ""
                                              "NTFSPermissions" = ""
                                              "CollectionDate" = $collection_date
                                              "TypeInfo" = $CurrnetTypeInfo
                                             }
    }
}

$r = $r | select ComputerName, name, caption, path, status, Type, SharePermissions, FolderName, GroupUser, NTFSPermissions, CollectionDate, TypeInfo

if ($r) {$r = [pscustomobject]@{Type = $CurrnetTypeInfo; Data = $r}}
return $r