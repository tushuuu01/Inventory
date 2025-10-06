<#
    Сбор инвентаризационной информации
    
    Функция получает разрешения NTFS для каталога, включая вложенные каталоги.
    Уровень вложенности определяется параметром $Depth.

    $Depth = 0 - вложенные каталоги не определяются
    $Depth = 1 - первый уровень вложенности
    $Depth = 2 - второй уровень вложенности
    и тд
#>


Function Get-FolderAccess
{
    [CmdletBinding()]
    param (
            [parameter(ValueFromPipeline=$true)]
            [string] $Folder,

            [parameter(ValueFromPipeline=$true)]
            [int] $Depth = 1
          )    

    process{

    #возвращает вложенные каталоги
    Function Get-ChildFolder {
    Param (
            [string]$Folder,
            [int]$Depth = 1,
            [int]$CurrentDepth = 1
        )

        if ($Depth -gt 0)
        {
            Get-ChildItem -Path $folder -Directory -ErrorAction SilentlyContinue | foreach {
        
            $result = $_.FullName

            if ($CurrentDepth -lt $Depth)
            {
                Get-ChildFolder -folder $_.FullName -depth $Depth -CurrentDepth ($CurrentDepth + 1)
            }

            return $result
            }
        }
    } # function


    #возвращает разрешения для каталога
    Function FolderAcl ($folder) {
        
        $Acl = Get-Acl -Path $folder -ErrorAction SilentlyContinue -ErrorVariable ErrorGetAcl

        if ($ErrorGetAcl)
        {
            WriteLog "Не удается определить права для каталога $folder. Ошибка $ErrorGetAcl"
            return
        }

        $result = @()

        #определяем наличие подкаталогов с ненаследуемыми разрешениями по количеству подкаталогов
        $acl_inherited_count = ($Acl.Access | Where-Object IsInherited -eq $true).Count
        $acl_folder_count = $Acl.Access.Count

        ForEach ($Access in $Acl.Access) {
            if (-not $access.IsInherited -or $acl_inherited_count -ne $acl_folder_count)
            {
                $result += [pscustomobject]@{"FolderName" = "$folder"; "GroupUser" = "$($Access.IdentityReference)"; "NTFSPermissions" = ($access.FileSystemRights -Replace ", Synchronize", "")} 
                #$result += [pscustomobject]@{"FolderName" = "$folder"; "GroupUser" = "$($Access.IdentityReference)"; "NTFSPermissions" = [System.Security.AccessControl.FileSystemRights]$access.FileSystemRights} 
            }
        }
        return $result

    } # function


    $Output = @()

    #разрешения для корневого каталога
    $Output += FolderAcl -folder $Folder

    #получаем вложенные каталоги с уровнем вложености $Depth
    $FolderList = Get-ChildFolder -Folder $Folder -Depth $Depth

    #разрешения для вложенных каталогов
    $Output += $FolderList | ForEach-Object {FolderAcl -folder $_} 

    return $Output
    }
}
