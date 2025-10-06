<#
    Сбор инвентаризационной информации

    Проверяется наличие параметра $ParamName
        если параметр передан - проверяется наличие каталога
        если параметр не передан, или каталог не найден - проверяется каталог по умолчанию $DefaultFolderName в родительском каталоге

    Функция возвращает существующий каталог
#>

function CheckFolder {
    Param (
        [string]$ParamName,
        [string]$DefaultFolderName
    )

    $result = $null

    #получаем значение параметра $ParamName
    $folder = Get-Variable -Name $ParamName -ValueOnly

    #если параметр не передан
    if (!$Folder)
    {
        #получаем родительский каталог относительно каталога запуска добавляем к нему наименование папки по умолчанию $DefaultFolderName
        $ParentFolder = Join-Path $($global:PathScriptRoot | Split-Path -Parent) $DefaultFolderName
        if (Test-Path $ParentFolder)
        {
            $result = $ParentFolder
        }
        else
        {
            #создаем каталог в корне
            $NewFolder = Join-Path $global:PathScriptRoot $DefaultFolderName

            if (!(Test-Path $NewFolder))
            {
                [void]$(New-Item -Path $NewFolder -ItemType Directory)

                WriteLog  "Не задан параметр -$ParamName. Создан каталог $NewFolder."
            }
            
            $result = $NewFolder
        }

        if ($result)
        {
            WriteLog  "Не задан параметр -$ParamName. Будет использоваться каталог $result."
        }
    }
    #если параметр передан и переданный каталог не существует
    elseif (!(Test-Path $folder))
    {
        WriteLog "Не найден каталог $Folder. Прекращаем выполнение."
        break
    }
    else
    {
        #переданный параметр - каталог существует
        $result = $folder
    }

    return $result
}
