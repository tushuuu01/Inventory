<#
.SYNOPSIS
    Командлет сбора и обработка инвентаризационной информации
.DESCRIPTION
## Командлет позволяет выполнять:
- удаленный сбор инвентаризационной информации
- локальный сбор инвентаризационной информации
- обработку (объединение) инвентаризационной информации собранной с нескольких компьютеров.

### Удаленный сбор инвентаризационной информации
Удаленный сбор инвентаризационной информации предполагает запуск процедуры сбора на выделенном сетевом компьютере (сервере), имеющим доступ к объектам сбора.
Процедура удаленного сбора информации запускатся под учетной записью обладающим административными правами на объектах сбора.
Сбор инвентаризационной информации осуществляется с использованием запросов к объектам Windows Management Instrumentation (WMI) и системному реестру ОС Windows.
Возможен сбор инвентаризационной информации с компьютеров включенных в домен AD и расположенных в определенном OU, либо с компьютеров, имена которых перечислены в файле.

### Локальный сбор инвентаризационной информации
Локальный сбор инвентаризационной информации предполагает запуск процедуры сбора непосредственно на объекте сбора.
Локальный сбор может быть организован на СВТ как подключенных к сети, так и автономных.
Локальный сбор информации не требуется запускать под учетной записью обладающией адмнистративными правами на объектах сбора, при использовании запуска из планировщика предполагается запуск от SYSTEM.

Допускается использование локального и удаленного сбора совместно, например:
- удаленный сбор на компьютерах включенных в домен один домен;
- локальный сбор компьютерах включенных в другой домен и на автономных компьютерах.

### Обработка (объединение) инвентаризационной информации
Процедура обработки инвентаризационной информации предназначена для объединенния собранной по компьтерам информации, в файлы по типу инвентаризационной информации.
Так же процедура обеспечивает поддержку в актуальном состонии инвентаризационной информации путем удаления файлов инвентаризации старше заданного количества дней.
Обработка инвентаризационной информации не требует административных прав, требуются полные права на каталоги InvAnyComputers, InvResult и Logs.

    Структура:
    
    ```
    Inventory/
    |
    |-- Docs                             # Документация
    |   |-- Results                      # Расположение файлов результатов инвентаризации
    |   |-- Report			             # Расположение файла отчета XLS
    |   |    |- inv.xlsm     		     # Файл отчета XML
    |   |    |- inv.html.styles.css      # Файл стилей для HTML отчета
    |-- Src                              # Расположение командлета и скрипты запуска командлета
    |   |-- Modules                      # Основные скрипты командлета
    |   |    |- Get-Inventory-Module     # Расположение модулей командлета Get-Inventory
    |   |    |   |-- dsk.ps1             # Модуль сбора логических дисков
    |   |    |   |-- evt.ps1             # Модуль сбора событий включения и выключения
    |   |    |   |-- gpu.ps1             # Модуль сбора графических адаптеров
    |   |    |   |-- grp.ps1             # Модуль сбора состава локальных групп
    |   |    |   |-- hdd.ps1             # Модуль сбора физических дисков
    |   |    |   |-- hfx.ps1             # Модуль сбора установленных обновлений ОС
    |   |    |   |-- hwr.ps1             # Модуль сбора аппратной конфигураци
    |   |    |   |-- map.ps1             # Модуль сбора подключенных сетевых дисков
    |   |    |   |-- mnt.ps1             # Модуль сбора информации о подключенных мониторах
    |   |    |   |-- net.ps1             # Модуль сбора информации по сетевым интерфейсам
    |   |    |   |-- pci.ps1             # Модуль сбора PCI устройств
    |   |    |   |-- prf.ps1             # Модуль сбора профилей пользователей
    |   |    |   |-- ram.ps1             # Модуль сбора модули памяти
    |   |    |   |-- shr.ps1             # Модуль сбора информации по общим ресурса
    |   |    |   |-- svc.ps1             # Модуль сбора служб ОС
    |   |    |   |-- swr.ps1             # Модуль сбора установленного ПО
    |   |    |   |-- tsk.ps1             # Модуль сбора заданий планировщика
    |   |    |   |-- usr.ps1             # Модуль сбора локальных пользователей
    |   |    |-- Get-Inventory.ps1       # КомандлетGet-Inventory
    |   |    |-- CheckFolder.ps1         # Проверка используемых каталогов
    |   |    |-- CheckLogFile.ps1        # Проверка возможности ведения файла протокола
    |   |    |-- CheckOU.ps1             # Проверка параметра InvOU (OU AD)
    |   |    |-- CreateResult.ps1        # Модуль формирование итогового файла с результатами инвентаризации
    |   |    |-- DeleteOld.ps1           # Модуль удаления старых файлов инвентаризации
    |   |    |-- Get-Computer.ps1        # Командлет получения перечня компьютеров в домене
    |   |    |-- Get-FolderAccess.ps1    # Получение разрешений NTFS для каталога, включая вложенные каталоги
    |   |    |-- InvLocal.ps1            # Модуль локальной инвентаризации
    |   |    |-- InvType.ps1             # Формирование справочника типов инветаризации
    |   |    |-- ListComputers.ps1       # Получение переченя компьютеров с которых будет осуществлляться сбор
    |   |    |-- PollComputers.ps1       # Модуль удаленного сбора инвентаризации
    |   |    |-- SelectInvType.ps1       # Модуль выбора типов собираемой информатизации
    |   |    |-- UnZIP.ps1               # Модуль распаковки ZIP архивов с файлами инвентаризации
    |   |    |-- WriteLog.ps1            # Модуль записи в лог файл
    |   |-- InvLocal.cmd                 # Командный файл запуска процедуры локальной инвентаризации
    |   |-- InvLocal.ps1                 # Скрипт запуска локального сбора инвентаризации
    |   |-- InvRemote.ps1                # Скрипт запуска удаленного сбора инвентаризации
    |   |-- InvWork.ps1                  # Скрипт запуска обработки информации
    |   |-- Start-Inventory.psm1         # Командлет сбора и обработка инвентаризационной информации (этот файл)
    |   |-- Start-Inventory.psd1         # Манифест для Start-Inventory.psm1
    ```
.PARAMETER StartType
    Тип запуска командлета
        InvRemote - удаленный сбор
        InvLocal - локальный сбор
        CreateResult - обработка инвентаризационной информации
        InvRemoteCreateResult - удаленный сбор и обработка инвентаризационной информации (исползуется по умолчанию)

.PARAMETER InvFolderAnyComputers
    Каталог	хранения файлов данных инвентаризации по отдельным компьютерам. При локальном сборе - размещение файлов инвентаризации

.PARAMETER InvFolderResult
    каталог для сохранения итоговых результирующих файлов инвентаризации

.PARAMETER InvFolderZIPFiles
    каталог с ZIP файлами автономной инвентаризации. При локальном сборе - каталог размещения архива с данными инвентаризации

.PARAMETER InvFolderLog
    каталог размещения протоколов работы

.PARAMETER SelectInvType    
    Выбор типов инвентаризационной информации для сбора (если параметр не задан - выполняется сбор всех возможных типов информации)
        select - интерактивный выбор
        usr,net,svc - перечень типов для сбора

.PARAMETER InvComputerList
    перечень имен компьютеров с которых будет выполнен сбор
        file:Computers.csv - имя файла с перечнем копьютеров (заголовок в файле ComputerName), обязательно префикс file:
        Computer1, Computer2 - имена компьютеров

.PARAMETER InvOU
            Наименование OU в домене где расположены компьютеры с которых будет выполнен сбор
            При использовании параметра -InvOU требуется модуль PowerShell для Active Directory

.PARAMETER DayOld
    Количество дней хранения инвентаризационной информации в каталоге InvFolderAnyComputers

.PARAMETER InvRemoteDayOld
    Проверять наличие файлов инвентраизационной информации старше установленного количества дней перед удаленным сбором, по умолчанию 0 - не проверять

.PARAMETER ExtendLog
    Вести расширенный лог (протокол командлета Get-Inventory)
        $False - не вести расширенный протокол (по умолчанию)
        $True - не вести расширенный протокол

.PARAMETER ModuleParameters
    Дополнительные параметры модулей сбора
    Параметр передается в виде массива хэштаблиц:
                $Parameters = @(
                                 @{Module   = "shr"; VarName  = "DepthChildFolder"; VarValue = 2},
                                 @{Module   = "Тип модуля"; VarName  = "Наименование переменной"; VarValue = "Значение переменной"}
                                )
.EXAMPLE

    Удаленный сбор информации:
        Собрать инвентаризационную информацию со всех объектов из InvOU (distinguishedName) домена, расположений инвентаризацинный файлов по компютерам C:\Inventory\Src\Results\InvAnyComputers, результирующих файлов C:\Inventory\Src\Results\InvResult
            Start-Inventory -StartType InvRemote -InvFolderAnyComputers C:\Inventory\Src\Results\InvAnyComputers -InvFolderResult C:\Inventory\Src\Results\InvResult -InvOU OU=Servers,DC=domen,DC=ru

        Собрать инвентаризационную информацию со всех объектов из InvOU (distinguishedName) домена, расположений инвентаризацинный файлов по компютерам C:\Inventory\Src\Results\InvAnyComputers, результирующих файлов C:\Inventory\Src\Results\InvResult,
        дополнительно возможность интерактивного выбора типов инвентаризационной информации
            Start-Inventory -StartType InvRemote -InvFolderAnyComputers C:\Inventory\Src\Results\InvAnyComputers -InvFolderResult C:\Inventory\Src\Results\InvResult -InvOU OU=Servers,DC=domen,DC=ru -SelectInvType select

        Собрать инвентаризационную информацию со всех объектов из InvOU (distinguishedName) домена, расположений инвентаризацинный файлов по компютерам C:\Inventory\Src\Results\InvAnyComputers, результирующих файлов C:\Inventory\Src\Results\InvResult,
        выполнить сбор только указанных типов usr,net
            Start-Inventory -StartType InvRemote -InvFolderAnyComputers C:\Inventory\Src\Results\InvAnyComputers -InvFolderResult C:\InventorySrc\Results\\InvResult -InvOU OU=Servers,DC=domen,DC=ru -SelectInvType usr,net

        Собрать инвентаризационную информацию со всех объектов из InvOU (distinguishedName) домена, расположений инвентаризацинный файлов по компютерам C:\Inventory\Src\Results\InvAnyComputers, результирующих файлов C:\Inventory\Src\Results\InvResult,
        выполнить сбор с компьютеров из списка srv1, srv2
            Start-Inventory -StartType InvRemote -InvFolderAnyComputers C:\Inventory\Src\Results\InvAnyComputers -InvFolderResult C:\Inventory\Src\Results\InvResult -InvComputerList srv1, srv2

        Собрать инвентаризационную информацию со всех объектов из InvOU (distinguishedName) домена, расположений инвентаризацинный файлов по компютерам C:\Inventory\Src\Results\InvAnyComputers, результирующих файлов C:\Inventory\Src\Results\InvResult,
        выполнить сбор с компьютеров из файла
            Start-Inventory -StartType InvRemote -InvFolderAnyComputers C:\Inventory\Src\Results\InvAnyComputers -InvFolderResult C:\InventorySrc\Results\\InvResult -InvComputerList file:Computers.csv

        Выполнить обработку собранной инвентаризационной информации
            Start-Inventory -StartType CreateResult

        Собрать инвентаризационную информацию с локального компьютера, данные поместить в каталог C:\Inventory\Src\Results\InvAnyComputers, создать ZIP архив в каталоге InvFolderZIPFiles
            Start-Inventory -StartType InvLocal -InvFolderAnyComputers C:\Inventory\Src\Results\InvAnyComputers -InvFolderZIPFiles C:\Src\Results\Inventory\ZIP

.NOTES
    Новгородов Павел 05.2025
#>

function Start-Inventory {
    [cmdletbinding()]
    Param(
        #режим запуска 
        [Parameter (Mandatory=$False)]
        [ValidateSet("InvLocal","InvRemote", "CreateResult", "InvRemoteCreateResult")]
        [string]$StartType = "InvRemoteCreateResult",

        #выбор типов инвентаризационной информации для сбора
        [Parameter (Mandatory=$False)]
        [array]$SelectInvType,

        #перечень компютеров для сбора - имя файла или список имен
        [Parameter (Mandatory=$False)]
        [array]$InvComputerList,

        #OU с компьютерами для опроса
        [Parameter (Mandatory=$False)]
        [string]$InvOU,

        #Каталог для сохранения файлов инвентаризации по отдельным компьютерам
        [Parameter (Mandatory=$False)]
        [string]$InvFolderAnyComputers,

        #каталог для сохранения итоговых результирующих файлов инвентаризации
        [Parameter (Mandatory=$False)]
        [string]$InvFolderResult,

        #каталог с LOG файлами
        [Parameter (Mandatory=$False)]
        [string]$InvFolderLog,

        #каталог с ZIP файлами
        [Parameter (Mandatory=$False)]
        [string]$InvFolderZIPFiles,
        
        #актуальность инвентаризационных данных в днях
        [Parameter (Mandatory=$False)]
        [int]$DayOld,

        #вести расширенный протокол командлета Get-Inventory
        [Parameter (Mandatory=$False)]
        [boolean]$ExtendLog = $False,

        #дополнительные параметры модулей
        [Parameter (Mandatory=$False)]
        [array]$ModuleParameters,

        #проверять наличие файлов инвентраизационной информации старше установленного количества дней перед удаленным сбором
        [Parameter (Mandatory=$False)]
        [int]$InvRemoteDayOld = 0
    )

    process {

    #путь запуска скрипта
    $global:PathScriptRoot = $PSScriptRoot
    Set-Location -Path $PathScriptRoot

    #расположение папки Modules
    Set-Variable -Name FunctionFolder -Value "Modules" -Description "Каталог размещения скриптов"

    if (!(Test-Path $FunctionFolder))
    {
        Write-Host "Не найден каталог размещения модулей $FunctionFolder. Прекращаем выполнение."
        break
    }

    #загрузка скриптов из каталога
    "$(Join-Path $PathScriptRoot $FunctionFolder)\*" | Get-ChildItem -Include "*.ps1" | Import-Module -Force

    WriteLog "Запуск модуля инвентаризации"

    #имя лог файла
    $global:InvLogFile = CheckLogFile $InvFolderLog -StartType $StartType

    #проверка параметра -InvFolderAnyComputers - каталог размещения собранных файлов
    $InvAnyComputers = CheckFolder -ParamName "InvFolderAnyComputers" -DefaultFolderName "\Results\InvAnyComputers" 

    #если заданы дополнительные параметры модулей сбора, передаем их в глобальную переменную
    $global:MParameters = @()
    
    if ($ModuleParameters)
    {
        #проверяем наименование модулей в переданном параметре
        $CheckModuleName = $ModuleParameters.Module | Where-Object {$_ -in $global:InvType.Keys}

        if ($CheckModuleName)
        {
            $global:MParameters = $ModuleParameters
        }
        else
        {
            WriteLog "Не верно заданы имена модулей в параметре -ModuleParameters, параметр проигнорирован."
        }
    }

    #локальный сбор параметр -StartType InvLocal
    if ($StartType -eq "InvLocal")
    {
        WriteLog  "Запуск локальной процедуры сбора"

        #обработка параметра - SelectInvType
        $SelectInvTypeArray = SelectInvType -SelectInvType $SelectInvType -StartType $StartType

        InvLocal -InvLocalComputers $InvAnyComputers -InvLocalCompressFile $InvFolderZIPFiles -InvTypeSelect $SelectInvTypeArray -InvLocalDaysOld $DayOld -ExtendLog $ExtendLog
    }

    #удаленный сбор информации, параметры -StartType InvRemote, -StartType InvRemoteCreateResult
    if ($StartType -like "*Remote*")
    {
        #параметры InvComputerList и InvOU взаимоисключающие
        if ($InvComputerList -and $InvOU)
        {
            WriteLog "Параметры InvComputerList и InvOU взаимоисключающие. Прекращаем выполнение."
            break
        }
        
        WriteLog  "Запуск процедуры сбора"

        #проверка параметра -InvFolderResult - каталог размещения результирующих файлов
        $InvResult = CheckFolder -ParamName "InvFolderResult" -DefaultFolderName "Results\InvResult" 

        #проверка параметра $InvOU
        $InvOU = CheckOU -InvOU $InvOU -InvComputerList $InvComputerList

        #обработка параметра - SelectInvType
        $SelectInvTypeArray = SelectInvType -SelectInvType $SelectInvType -StartType $StartType

        #список компьютеров в зависимости от параметра $InvComputerList, иначе из OU
        $ComputerList = ListComputers -InvComputerList $InvComputerList -InvOU $InvOU -DayOld $DayOld
        
        #опрос компьютеров по полученному списку
        if ($ComputerList)
        {
            $ComputerList = PollComputers -ComputerList $ComputerList -SaveInvPath $InvAnyComputers -InvTypeSelect $SelectInvTypeArray -ExtendLog $ExtendLog -InvRemoteDayOld $InvRemoteDayOld

            $ExportFileName = "inv.last.poll.csv"
            WriteLog "Экспортируем результат опроса $InvResult\$ExportFileName"
            $ComputerList | Export-Csv (Join-Path $InvResult $ExportFileName) -Encoding UTF8 -NoTypeInformation
        }
        else
        {
            WriteLog "Не получен перечень компьютеров для опроса."
        }
    }

    #процедура обработки информации, параметры -StartType CreateResult, -StartType InvRemoteCreateResult
    if ($StartType -like "*Result*") 
    {
        WriteLog "Старт процедуры обработки файлов инвентаризации"

        #проверка параметра -InvFolderResult - каталог размещения результирующих файлов
        $InvResult = CheckFolder -ParamName "InvFolderResult" -DefaultFolderName "Results\InvResult" 

        #если задан параметр InvOU - экспортируем компьютеры из OU
        if ($InvOU)
        {
            #проверка наличия модуля PowerShell ActiveDirectory
            CheckADPowerShell

            $ExportFileName = "inv.ou.$env:USERDOMAIN.csv"
            $ComputerList = Get-Computer -OUName $InvOU -LastLogonDay $DayOld
            WriteLog "Экспортируем перечень компьютеров из OU $InvOU (количество $($ComputerList.Count)) $InvResult\$ExportFileName"
            $ComputerList | Export-Csv (Join-Path $InvResult $ExportFileName) -Encoding UTF8 -NoTypeInformation
        }

        #обработка ZIP файлов локальной инвентаризации 
        UnZIP -InvZIPFiles $InvFolderZIPFiles -InvAnyComputers $InvAnyComputers

        #удаление старых файлов инвентаризации
        if ($DayOld) 
        {
            DeleteOld -InvAnyComputers $InvAnyComputers -DayToDelete $DayOld
        }

        #объединение файлов инвентаризации по компьютерам в общие файлы по типу информации
        $p = @{
                InvResult          = $InvResult;
                InvAnyComputers    = $InvAnyComputers;
                InvLog             = $InvFolderLog;
                InvZIPFiles        = $InvFolderZIPFiles;
                DayToDelete        = $DayOld;
                SelectInvTypeArray = $SelectInvTypeArray;
              }
        CreateResult @p
    }

    } #process
} #function
