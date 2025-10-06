<#
    Запуск локального сбора инвентаризации

    Примеры запуска:
        Собрать информацию с локального комьютера, если не заданы параметры -InvFolderAnyComputers и -InvFolderResult будут созданы и использованы каталоги в корне.
            Start-Inventory -StartType InvLocal
        
        Собрать информацию с локального комьютера в каталог C:\Inventory\Src\InvAnyComputers, если ранее собранные данные не старее 5 дней.
            Start-Inventory -StartType InvLocal -InvFolderAnyComputers C:\Inventory\InvAnyComputers -DayOld 5

        Собрать информацию с локального комьютера в каталог C:\Inventory\Src\InvAnyComputers, лог файл в каталоге C:\Inventory\Logs
            Start-Inventory -StartType InvLocal -InvFolderAnyComputers C:\Inventory\InvAnyComputers -InvFolderLog C:\Inventory\Logs

        Собрать информацию с локального комьютера в каталог C:\Inventory\Src\InvAnyComputers.
        Сформировать ZIP архив собранных данных в каталоге C:\Inventory\ZIP
            Start-Inventory -StartType InvLocal -InvFolderAnyComputers C:\Inventory\Src\InvAnyComputers -InvFolderLog C:\Inventory\Logs

        Собрать информацию типа "hdd", "pci" с локального комьютера в каталог C:\Inventory\Src\InvAnyComputers.
            Start-Inventory -StartType InvLocal -InvFolderAnyComputers C:\Inventory\Src\InvAnyComputers -SelectInvType "hdd", "pci"

        В случае если требуется для модуля shr задать параметр DepthChildFolder, например  равный 2 (получить разрешения для общих ресусов, включая каталоги с глубиной вложенности 2), 
        необходимо определить параметр в хэш-таблице массива и передать его в параметр -ModuleParameters $m:
            $m = @(@{Module   = "shr"; VarName  = "DepthChildFolder"; VarValue = 2})
            Start-Inventory -StartType InvLocal -InvFolderAnyComputers C:\Inventory\InvAnyComputers -ModuleParameters $m

#>

Set-Location -Path $PSScriptRoot

Import-Module .\Start-Inventory.psm1 -Force

Start-Inventory -StartType InvLocal -DayOld 5 #-ModuleParameters $m