<#
    Сбор инвентаризационной информации
    Модуль формирование итогового файла с результатами инвентаризации

    По каждому типу инвентаризационной информации формируется отдельный файл.

    Выполняется объединение файлов с инвентаризацией по компютерам расположенных в каталоге InvAnyComputers
    Результат объединения, один файл по каждому типу информации, размещается в каталоге InvResult
    Объединяемые файлы вида xxxx.TTT.csv, где xxxx - имя компьютера, TTT - тип информации (три символа)
    Результирующий файл вида TTT.csv
    Дополнительно формируются файлы:
    - inv.date.count.csv - количество компьютеров по датам сбора информации
    - inv.stat.csv - статистика сбора
    - inv.all.comp.csv - перечень комьютеров с типом собранной информации
    - inv.type.comp.csv - количество собранной информации по типам
    - inv.ou.comp.csv - перечень компютеров выгруженных из OU, на основе файлов выгруженных из других доменов inv.ou.*.csv

    Обрабатывается параметр InvTypeFileName, выбранные типы инвентаризации (-SelectInvType), выполняется объединение только по ним.
#>

Function CreateResult {
    Param(
        [string]$InvResult,
        [string]$InvAnyComputers,
        [string]$InvLog,
        [string]$InvZIPFiles,
        [int]$DayToDelete,
        [array]$SelectInvTypeArray
    )

    #получаем перечень файлов в папке инвентаризации по маске xxxx.TTT.csv
    #формируем список Имя копьютера, Тип инв, Время создания, Имя файла, полный путь, размер
    # -match '\.\w\w\w\.csv' - \. - точка, \w - буква
    $inv_computers_list = Get-ChildItem -Path $InvAnyComputers | Where-Object {$_.Name -match '\.\w\w\w\.csv'} | `
                                                                select @{name = "ComputerName"; expression ={$_.name.Split(".")[0]}},`
                                                                @{name = "Type"; expression ={$_.name.Split(".")[1]}},`
                                                                LastWriteTime, Name, FullName, Length
    #статистика
    $statistic = [ordered]@{}
    $statistic.add("1. Дата обработки", (Get-Date).ToShortDateString())
    $statistic.add("2. Каталог сохранения файлов инвентаризации (InvAnyComputers)",$InvAnyComputers)
    $statistic.add("3. Каталог результирующих файлов (InvResult)",$InvResult)
    $statistic.add("4. Каталог файлов протоколов работы (InvLog)",$InvLog)
    $statistic.add("5. OU расположения объектов «Компьютер» в домене (InvOU)",$InvOU)
    $statistic.add("6. Каталог расположения ZIP файлов инвентаризации с локальных СВТ (InvZIPFiles)",$InvZIPFiles)
    $statistic.add("7. Удалять файлы инвентаризации старше указанного количества дней",$DayToDelete)


    #всего файлов инвентаризации
    $s = $inv_computers_list.Count
    $statistic.add("8. Файлов инвентаризации","$s ({0:N2} Мб)" -f (($inv_computers_list | Measure-Object Length -Sum).Sum / 1Mb))

    #количество компьютеров с которых собрана инвентаризация
    $s = $inv_computers_list | select ComputerName | Group-Object -Property ComputerName
    $statistic.add("9. Компьютеров", $s.Name.Count)

    #если получен перечень файлов с инвентаризацией
    if ($inv_computers_list)
    {
        <#
            Формирование пустого inv.last.poll.csv - перечень компьютеров с которых была собрана инвентаризация 
            если он не существует
        #>
            $ExportFileName = Join-Path $InvResult "inv.last.poll.csv"

            if (!(Test-Path $ExportFileName))
            {
                New-Item -ItemType File -Path $ExportFileName -Value '"ComputerName","CollectionDate","NetAccess","PSAccess","InvStatus"' -Force | Out-Null
            }

        <#
            Формирование inv.type.comp.csv - перечень типов информации с количеством компютеров с которых она собрана
                                             Name, Description, Count
        #>
            $ExportFileName = Join-Path $InvResult "inv.type.comp.csv"

            $InvTypeFiles = $inv_computers_list | Group-Object -Property Type | Select Name, @{Name = "Description"; expression={$global:InvType[$_.Name]}}, Count
            $InvTypeFiles | Export-Csv -Path $ExportFileName -Encoding UTF8 -NoTypeInformation

        <#
            Формирование inv.all.comp.csv - перечень компьютеров с которых собрана инвентаризация
                                            с последней датой сбора и результатом
                                            ComputerName, CollectionDate, InvRecive, InvNotRecive
        #>
            $ExportFileName = Join-Path $InvResult "inv.all.comp.csv"

            $s = $inv_computers_list | select ComputerName, Type, @{Name = "Date"; expression={$_.LastWriteTime.ToShortDateString()}} | `
                                       #группируем по имени компьютера 
                                       group ComputerName | `
                                       select @{Name = "ComputerName"; expression={$_.Name}}, `
                                              #выборка последней даты из группировки
                                              @{Name = "CollectionDate"; expression={($_.Group | sort Date | select -Last 1).Date }},`
                                              #собранные типы информации
                                              @{Name="InvRecive"; expression={$_.Group.Type}},`
                                              #несобранный типы информации
                                            @{Name="InvNotRecive"; expression={(Compare-Object -ReferenceObject @($global:InvType.Keys) -DifferenceObject @($_.Group.Type)).InputObject } }
            $s | Export-Csv -Path $ExportFileName -Encoding UTF8 -NoTypeInformation

        <#
            Формирование inv.date.count.csv - количество компьютеров по дате инвентаризации
                                              Дата инвентаризации, Количество
        #>
            $ExportFileName = Join-Path $InvResult "inv.date.count.csv"

            $s = $inv_computers_list | select ComputerName, @{Name = "Date"; expression={$_.LastWriteTime.ToShortDateString()}} |`
                                       sort ComputerName, Date -Descending | `
                                       group ComputerName | `
                                       foreach {$_.Group[0]} |`
                                       group Date |`
                                       select @{Name="Дата инвентаризации"; expression={$_.Name}}, @{Name="Количество"; expression={$_.Count}}
            $s | Export-Csv -Path $ExportFileName -Encoding UTF8 -NoTypeInformation

        <#
            Актуальность данных старый и свежий файлы. Сортируем. Получаем первый и последний файл
        #>
            $s = $inv_computers_list | sort LastWriteTime | select LastWriteTime
            $d1 = ($s | select -First 1).LastWriteTime.ToShortDateString()
            $d2 = ($s | select -Last 1).LastWriteTime.ToShortDateString()
            $statistic.add("10. Актуальность данных", "$d1 - $d2")

        <#
            Обработка файлов инвентаризации
            Объединение файлов по компьютерам в файлы по типам инветаризации
            InvAnyComputers -> InvResult
        #>
            WriteLog "Будет выполнено объединение файлов инвентаризации компьютеров по типу"
            WriteLog "Файлы инвентаризции компьютеров: $InvAnyComputers"
            WriteLog "Результирующие файлы: $InvResult"

            #время начала обработки
            $stat_time_work_csv = Get-Date

            #если есть переменная $SelectInvTypeArray содержащая перечень модулей сбора - будем объединять файлы только по этим типам
            if ($SelectInvTypeArray)
            {
                $InvTypeFiles = $InvTypeFiles | Where-Object {$_.Name -in $SelectInvTypeArray.InvType}
            }

            #формируем пустые файлы по типу инвентаризации
            $global:InvType.Keys | `
                                    select @{Name = "Path"; expression = {Join-Path $InvResult "$_.csv"}} | `
                                    foreach {
                                                if (!(Test-Path $_.Path))
                                                {
                                                    New-Item -Path $_.Path -ItemType "file" -Value "" -Force | Out-Null
                                                }
                                            }
                                    
            #для каждого типа информации формируем результирующий файл по всем СВТ
            foreach($type in $InvTypeFiles.Name)
            {
                #предварительно удаляем результирующий файл
                Remove-Item (Join-Path $InvResult "$type.csv") -ErrorAction SilentlyContinue

                WriteLog "Формируем результат по типу: $type - $InvResult\$type.csv"

                #получаем файлы по компьютерам одного типа - формируем результирующий файл
                $inv_computers_list | Where-Object {$_.Name -match "\.$type.csv"} | foreach {Import-Csv $_.FullName | Export-Csv -Path (Join-Path $InvResult "$type.csv") -Append -Encoding UTF8 -NoTypeInformation}
            }

            $time_work_csv = New-TimeSpan -Start $stat_time_work_csv -End (Get-Date)

            WriteLog "Время обработки файлов CSV $($time_work_csv.TotalSeconds) сек."

            $statistic.add("11. Время обработки файлов CSV", "{0:hh}:{0:mm}:{0:ss}" -f $time_work_csv)
    }
    else
    {
        WriteLog "Нет данных для объединения"
    }

    <#
        Формирование inv.ou.comp.csv - перечень компютеров выгруженных из OU
        На основе файлов выгруженных из других доменов inv.ou.*.csv
    #>
    $ExportFileName = Join-Path $InvResult "inv.ou.csv"
    $MatchName = "inv.ou.\S{1,}.csv"
    
    WriteLog "Формируем перечень компьютеров из OU на основе файлов по маске $MatchName"
    WriteLog "Перечень компьютеров $ExportFileName"

    #если файлы inv.ou.*.csv есть, формируем на основе файлов inv.ou.*.csv - файл inv.ou.comp.csv
    $computers_list = Get-ChildItem -Path $InvResult | Where-Object {$_.Name -match $MatchName}

    if ($computers_list)
    {
        WriteLog "Получено файлов выгрузки из OU: $computers_list"
        Remove-Item $ExportFileName -ErrorAction SilentlyContinue
        $computers_list | foreach {Import-Csv $_.FullName | Export-Csv -Path $ExportFileName -Append -Encoding UTF8 -NoTypeInformation}    
    }
    #если файлов inv.ou.*.csv нет, формируем пустой файл inv.ou.comp.csv
    else
    {
        $EmptyValue = '"ComputerName","ComputerDomain","ComputerOS","ComputerDescription","NetAccess","PSAccess","CollectionDate","ComputerOU","InvStatus"'
        New-Item -Path $ExportFileName -ItemType "file" -Value $EmptyValue -Force | Out-Null
        WriteLog "Файлов $MatchName не найдено"
    }

    #сохраняем статистику
    $ExportFileName = "inv.stat.csv"
    $statistic.GetEnumerator() | select Key, Value | Export-Csv -Path (Join-Path $InvResult $ExportFileName) -Encoding UTF8 -NoTypeInformation
}