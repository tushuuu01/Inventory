<#
    Сбор инвентаризационной информации
    Модуль сбора заданий планировщика

    Наименование типа инвентаризационой информации - не удалять!

    <Description>Задания планировщика</Description>
#>

#перечень папок планировщика для получения заданий
$TaskFolders = "\", "\Microsoft\Windows\Application Experience"

#получаем имя текущей функции (имя функции Get-Inv-ххх), из него тип собираемой информации
$CurrnetTypeInfo = ($MyInvocation.MyCommand.Name -split "-")[-1]

$r = $null

$Schedule = New-Object -ComObject "Schedule.Service"

$tasks = @()

if ($LocalComputer)
{
    $Schedule.Connect()    
}
else
{
    $Schedule.Connect($ComputerName)    
}

$TaskFolders | ForEach-Object { $tasks += $Schedule.GetFolder($_).GetTasks(0) }
                                                              
$r =  $tasks | select @{Name="TaskName"; Expression={$_.Name}},`
                      Enabled,`
                      Path,`
                      LastRunTime,`
                      NextRunTime,`
                      LastTaskResult,`
                      @{Name="RunAs"; Expression={[xml]$xml=$_.xml; $xml.task.Principals.principal.UserId}},`
                      @{Name="Author"; Expression={[xml]$xml=$_.xml; $xml.task.RegistrationInfo.Author}},`
                      @{Name="Command"; Expression={[xml]$xml=$_.xml; $xml.task.Actions.Exec.Command}},`
                      @{Name="Arguments"; Expression={[xml]$xml=$_.xml; $xml.task.Actions.Exec.Arguments}}

  
$r = $r | select @{Name="ComputerName"; Expression={$ComputerName}}, `
                 TaskName, `
                 Path, `
                 Enabled, `
                 LastRunTime, `
                 NextRunTime, `
                 LastTaskResult, `
                 Author, `
                 @{Name="RunAs"; expression = {([Security.Principal.securityidentifier]$_.RunAs).Translate([Security.Principal.ntaccount]).Value}}, `
                 @{Name="Command"; expression={$_.Command + " " + $_.Arguments}}, `
                 @{Name="CollectionDate"; Expression={$collection_date}}, `
                 @{Name="TypeInfo"; Expression={$CurrnetTypeInfo}}

if ($r) {$r = [pscustomobject]@{Type = $CurrnetTypeInfo; Data = $r}}
return $r