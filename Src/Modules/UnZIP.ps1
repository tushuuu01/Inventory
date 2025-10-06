<#
    Сбор инвентаризационной информации
    Модуль распаковки ZIP архивов с файлами инвентаризации

    Файлы ZIP из папки InvZIPFiles распаковываются в папку InvAnyComputers
#>

Function UnZIP {
    Param (
        [string]$InvZIPFiles,
        [string]$InvAnyComputers
    )

    if ($InvZIPFiles -and (Test-Path $InvZIPFiles) -and (Test-Path $InvAnyComputers))
    {
    
        WriteLog "Старт процесса распаковки ZIP. Входной каталог $InvZIPFiles, выходной каталог $InvAnyComputers"

        Add-Type -AssemblyName "System.IO.Compression.FileSystem"
    
        #получаем перечень ZIP файлов с использованием рекурсии
        $zip_files = Get-ChildItem -Path $InvZIPFiles -Recurse | Where-Object {$_.Name -match 'inv.*.zip'}

        WriteLog "Обнаружено ZIP файлов: $($zip_files.count)"

        foreach($zip_file in $zip_files.FullName)
        {
            $zip = [System.IO.Compression.ZipFile]::OpenRead($zip_file)

            WriteLog "Обработка файла $zip_file. Файлов в архиве $($zip.Entries.Count)"

            foreach ($entry in $zip.Entries)
            {
                $entryTargetFilePath = [System.IO.Path]::Combine($InvAnyComputers, $entry.FullName)
                $entryDir = [System.IO.Path]::GetDirectoryName($entryTargetFilePath)
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $entryTargetFilePath, $true);
            }
            $zip.Dispose()

            #удаляем распакованный файл
            WriteLog "Удаляем распакованный файл $zip_file"
            Remove-Item $zip_file -ErrorAction SilentlyContinue

            WriteLog "Завершение процесса распаковки ZIP"
        } #foreach
    }
}