<#
    Сбор инвентаризационной информации
    Получает перечень типов инвентаризационной информации для сбора
    Если задан параметр -SelectInvType select будет выдан интерактивный список типов информации
    Возвращает выбранные типы информации:
        InvType - тип инвентаризации (три символа)
        PsName - имя модуля PS (InvType.ps1)
        
#>

function SelectInvType {
    Param (
            [array]$SelectInvType,
            [string]$StartType
    )

    $result = @()

    #интерактивный выбор типа инвентаризационной информации, если не локальный сбор
    if ($SelectInvType -eq "select" -and $StartType -ne "InvLocal")
    {
        #окно выбора типа инвентаризации
        $result = $global:InvType | Out-GridView -Title "Выберите из списка типы информации для сбора и нажмите ОК. Для завершения нажмите Cancel" -PassThru

        if (!$result) 
        {
            break
        }

        #добавляем к имени файла расширение
        $result = $result | select @{Name = "InvType"; expression={$_.Name}}, @{Name = "PsName"; expression={"$($_.Name).ps1"}}
    }
    elseif ($SelectInvType)
    {
        #убираем повторы если есть
        $SelectInvType = $SelectInvType | Sort-Object | Get-Unique

        #проверяем принадлежность переданных типов инвентаризации в списке типов из справочника
        $result= $global:InvType.Keys | Where-Object {$SelectInvType -contains $_}

        #добавляем к имени файла расширение
        $result = $result | select @{Name = "InvType"; expression={$_}}, @{Name = "PsName"; expression={"$($_).ps1"}}
    }

    #запись в протокол
    if ($SelectInvType)
    {
        WriteLog "Получен параметр запуска SelectInvType"

        if ($result)
        {
            WriteLog "Выбраны типы инфомации для сбора: $($result.InvType -join ',')"
        }
        else
        {
            WriteLog "Не определы типы инвентаризации в параметре SelectInvType. Параметр проигнорирован."
        }
    }

    return $result
}