<#
    Сбор инвентаризационной информации
    Модуль сбора установленного ПО

    Наименование типа инвентаризационой информации - не удалять!

    <Description>Установленное ПО</Description>

    
    Описание: перечень установленного ПО получается путем чтения значений ключа реестра "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\", "HKLM:Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"
#>

#получаем имя текущей функции (имя функции Get-Inv-ххх), из него тип собираемой информации
$CurrnetTypeInfo = ($MyInvocation.MyCommand.Name -split "-")[-1]

#ключи реестра для опроса установленного ПО
$RegItem = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\", "HKLM:Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"

$r = @()

#локальный компьютер
$LocalComputer = $ComputerName -eq $env:COMPUTERNAME

#получаем перечень установленного ПО на указанном компьютере
#если компьютер локальный
if ($LocalComputer)
{
            #получаем перечень ПО
            $program_list = Get-ChildItem -Path $RegItem -ErrorAction SilentlyContinue | `
                                Get-ItemProperty | Where-Object {$_.DisplayName -ne $null} | `
                                Select-Object @{Name="ComputerName"; Expression={$ComputerName}}, `
                                              @{Name="DisplayName"; Expression={$_.DisplayName -replace "[`n`r]", ""}},`
                                              @{Name="DisplayVersion"; Expression={$_.DisplayVersion -replace "[`n`r]", ""}},`
                                              @{Name="Publisher"; Expression={$_.Publisher -replace "[`n`r]", ""}},`
                                              @{Name="Bit"; Expression={if ($_.PSPath -like "*Wow6432Node*") {"32"} else {"64"}}}, `
                                              @{Name="InstallDate"; expression={
                                                                                 if ($_.InstallDate) {([datetime]::parseexact($_.InstallDate, "yyyyMMdd", $null)).ToShortDateString()}
                                                                                }}, `
                                              @{Name="CollectionDate"; Expression={$collection_date}}, @{Name="TypeInfo"; Expression={$CurrnetTypeInfo}} | Where-Object  {$_.SystemComponent -ne 1}
}
else
{
            #если компьютер удаленный
            #получаем перечень ПО
            $program_list = Invoke-Command -ComputerName $ComputerName `
                                 -ScriptBlock { 
                                                 Get-ChildItem -Path $Using:RegItem -ErrorAction SilentlyContinue | `
                                                 Get-ItemProperty | Where-Object {$_.DisplayName -ne $null} | `
                                                 Select-Object @{Name="ComputerName"; Expression={$Using:ComputerName}}, `
                                                      @{Name="DisplayName"; Expression={$_.DisplayName -replace "[`n`r]", ""}},`
                                                      @{Name="DisplayVersion"; Expression={$_.DisplayVersion -replace "[`n`r]", ""}},`
                                                      @{Name="Publisher"; Expression={$_.Publisher -replace "[`n`r]", ""}},`
                                                      @{Name="Bit"; Expression={if ($_.PSPath -like "*Wow6432Node*") {"32"} else {"64"}}}, `
                                                      @{Name="InstallDate"; expression={
                                                                                        if ($_.InstallDate) {([datetime]::parseexact($_.InstallDate, "yyyyMMdd", $null)).ToShortDateString()}
                                                                                        }}, `
                                                      @{Name="CollectionDate"; Expression={$Using:collection_date}}, @{Name="TypeInfo"; Expression={$Using:CurrnetTypeInfo}} | Where-Object  {$_.SystemComponent -ne 1}
                                           }
}
                
$program_list = $program_list | select ComputerName, DisplayName, DisplayVersion, Publisher, InstallDate, Bit, CollectionDate, TypeInfo

if ($program_list) {$r = [pscustomobject]@{Type = $CurrnetTypeInfo; Data = $program_list}}
return $r