 <#
    Запуск процедуры обработки информации

    Примеры запуска:
        Обработка файлов инвентаризации, если не заданы параметры -InvFolderAnyComputers и -InvFolderResult будут созданы и использованы каталоги в корне
            Start-Inventory -StartType CreateResult

        Обработка файлов инвентаризации в каталоге C:\Inventory\Src\InvAnyComputers, результат в каталоге C:\Inventory\Src\InvResult, лог файл в каталоге C:\Inventory\Logs
            Start-Inventory -StartType CreateResult -InvFolderAnyComputers C:\Inventory\Src\InvAnyComputers -InvFolderResult C:\Inventory\Src\InvResult -InvFolderLog C:\Inventory\Logs

        Распаковка ZIP файлы с инвентаризацией из каталога C:\Inventory\ZIP в каталог C:\Inventory\Src\InvAnyComputers
        Удаление в каталоге C:\Inventory\InvAnyComputers файлов старше 60 дней.
        Обработка файлов инвентаризации в каталоге C:\Inventory\Src\InvAnyComputers, результат в каталоге C:\Inventory\Src\InvResult.
        Выгрузка компьютеров в домене из OU "OU=хххх,DC=xxx,DC=xx,DC=xx" с LastLogonDatе больше меньше 60 дней (задание параметра -DayOld позволяет не выгружать из домена компьютеры которые не используются).
            Start-Inventory -StartType CreateResult -InvFolderAnyComputers C:\Inventory\Src\InvAnyComputers -InvFolderResult C:\Inventory\Src\InvResult -InvFolderLog -InvFolderZIPFiles C:\Inventory\ZIP -DayOld 60

#>

Import-Module .\Start-Inventory.psm1 -Force

$param = @{
            StartType             = "CreateResult";
            InvFolderAnyComputers = "C:\Inventory\Src\Results\InvAnyComputers";
            InvFolderResult       = "C:\Inventory\Src\Results\InvResult";
            InvFolderLog          = "C:\Inventory\Src\Logs";
            InvOU                 = "OU=хххх,DC=xxx,DC=xx,DC=xx";
            InvFolderZIPFiles     = "C:\Inventory\ZIP";
            DayOld                = 60
}
#Start-Inventory @param

Start-Inventory -StartType CreateResult -DayOld 60