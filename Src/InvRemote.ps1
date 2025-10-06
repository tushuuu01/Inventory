<#
    Запуск удаленного сбора инвентаризации
#>

Import-Module .\Start-Inventory.psm1 -Force

<#
    Варианты запуска с использованием параметров переданных с использованием хэш таблицы:
        #Start-Inventory @param1

    Так же можно передавать параметры непосредственно:
        Start-Inventory -StartType InvRemoteCreateResult -InvFolderAnyComputers C:\Inventory\Src\InvAnyComputers -InvFolderResult C:\Inventory\Src\InvResult -InvFolderLog C:\Inventory\Src\Logs

#>

<#
    Запустить сбор и обработку собранной информации
    с компьютеров расположенных в текущем OU в каталоги InvAnyComputers и InvResult расположенные в родительском каталоге (если в родительском каталоге их нет - будут созданы в текущем)
    Запустить командлет без параметров
#>
$param = @{
}

<#
    Удалить файлы в каталоге C:\Inventory\Src\InvAnyComputers старше 60 дней.
    Запустить удаленный сбор с доменных компьютеров расположенных в OU "OU=xxxx,DC=xxx,DC=xx,DC=xx" в каталог  C:\Inventory\Src\InvAnyComputers.
    Распаковать файлы ZIP из каталога C:\Inventory\ZIP в каталог C:\Inventory\Src\InvAnyComputers.
    Обработать файлы в каталоге C:\InventorySrc\InvAnyComputers, результат в каталог C:\Inventory\Src\InvResult.
    Лог файл в каталоге C:\Inventory\Src\Logs.
#>
$param1 = @{
            StartType             = "InvRemoteCreateResult";
            InvFolderAnyComputers = "C:\Inventory\Src\InvAnyComputers";
            InvFolderResult       = "C:\Inventory\Src\InvResult";
            InvFolderLog          = "C:\Inventory\Src\Logs";
            InvOU                 = "OU=xxxx,DC=xxx,DC=xx,DC=xx";
            InvFolderZIPFiles     = "C:\Inventory\ZIP";
            DayOld                = 60
}

<#
    Удалить файлы в каталоге C:\Inventory\Src\InvAnyComputers старше 60 дней.
    Запустить удаленный сбор с компьютеров перечисленных в файле Computers.csv в каталог  C:\Inventory\Src\InvAnyComputers.
    Обработать файлы в каталоге C:\Inventory\Src\InvAnyComputers, результат в каталог C:\Inventory\Src\InvResult.
    Лог файл в каталоге C:\Inventory\Logs.
#>
$param2 = @{
            StartType             = "InvRemoteCreateResult";
            InvFolderAnyComputers = "C:\Inventory\Src\InvAnyComputers";
            InvFolderResult       = "C:\Inventory\Src\InvResult";
            InvFolderLog          = "C:\Inventory\Logs";
            InvComputerList       = "file:Computers.csv";
            DayOld                = 60
}

<#
    Запустить удаленный сбор информации типа "net","pci","ram"  с компьютеров "Server1", "Server2" в каталог  C:\Inventory\InvAnyComputers.
    Лог файл в каталоге C:\Inventory\Logs.
#>
$param3 = @{
            StartType             = "InvRemote";
            InvFolderAnyComputers = "C:\Inventory\Src\InvAnyComputers";
            InvFolderResult       = "C:\Inventory\Src\InvResult";
            InvFolderLog          = "C:\Inventory\Logs";
            InvComputerList       = "server1", "server2";
            SelectInvType         = "net","pci","ram";
}

<#
    Запустить удаленный сбор информации интерактивно выбранных типов с компьютеров расположенных в текущем OU в каталог  C:\Inventory\InvAnyComputers.
    Лог файл в каталоге C:\Inventory\Logs.
#>
$param4 = @{
            StartType             = "InvRemote";
            InvFolderAnyComputers = "C:\Inventory\Src\InvAnyComputers";
            InvFolderResult       = "C:\Inventory\Src\InvResult";
            InvFolderLog          = "C:\Inventory\Logs";
            SelectInvType         = "select";
}

#запуск с параметрами переданными в переменной
#Start-Inventory @param1


<#
    Запустить удаленный сбор с компьютеров расположенных в текущем OU в каталог  C:\Inventory\InvAnyComputers.
    Для модуля shr задать параметр DepthChildFolder = 1 (получить разрешения для общих ресусов, включая каталоги с глубиной вложенности 1)
#>
$m1 = @(@{Module   = "shr"; VarName  = "DepthChildFolder"; VarValue = 1})
#Start-Inventory -StartType InvRemote -InvFolderAnyComputers"C:\Inventory\InvAnyComputers" -ModuleParameters $m1

<#
    Запустить удаленный сбор с компьютеров расположенных в текущем OU в каталог  C:\Inventory\InvAnyComputers.
    Для модуля shr задать параметр DepthChildFolder = -1 (не получать NTFS разрешения для каталогов общих ресурсов)
#>
$m2 = @(@{Module   = "shr"; VarName  = "DepthChildFolder"; VarValue = -1})
#Start-Inventory -StartType InvRemote -InvFolderAnyComputers"C:\Inventory\InvAnyComputers" -ModuleParameters $m2

<#
    Запустить удаленный сбор с компьютеров расположенных в текущем OU в каталог  C:\Inventory\InvAnyComputers.
    Для модуля shr задать параметр DepthAnyComputer - задать для указанных компьютеров уровень вложенности каталогов для общих ресурсов.
    При этом для всех остальных компьютеров будет использоваться значение параметра DepthChildFolder = 0 по умолчанию.
#>
$m3 = @(
            @{Module = "shr"; VarName = "DepthChildFolder"; VarValue = -1},

            @{Module = "shr"; VarName = "DepthAnyComputer"; VarValue = ("fs*", 2), ("fs03", 2), ("fs04", 3), ("fs06", 0), ("as40", 2), ("ap18", 2), ("sf01", 0)}
        )
#Start-Inventory -StartType InvRemote -InvFolderAnyComputers"C:\Inventory\Src\InvAnyComputers" -ModuleParameters $m3

Start-Inventory -StartType InvRemote