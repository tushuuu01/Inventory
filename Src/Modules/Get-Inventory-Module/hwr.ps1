<#
    Сбор инвентаризационной информации
    Модуль сбора аппратной конфигурации

    Наименование типа инвентаризационой информации - не удалять!

    <Description>Программно-аппаратная конфигурация</Description>
#>

#получаем имя текущей функции (имя функции Get-Inv-ххх), из него тип собираемой информации
$CurrnetTypeInfo = ($MyInvocation.MyCommand.Name -split "-")[-1]

$hwr = New-Object PSCustomObject
$hwr | Add-Member -Membertype NoteProperty -Name ComputerName -value $ComputerName

#Доступное дисковое пространство
$r = $null
$r = Get-WmiClass -ComputerName $ComputerName -ClassName "Win32_LogicalDisk" -cimSession $cimSession -PSver $PSver
$r = $r | Where-Object {$_.DriveType -eq 3} 

$d = $r | Measure-Object FreeSpace, Size -Sum | select Property, Sum
$hwr | Add-Member -Membertype NoteProperty -Name HDDSize -value ([math]::Round(($d | Where-Object {$_.Property -like "Size"}).Sum/1GB, 0))
$hwr | Add-Member -Membertype NoteProperty -Name HDDFreeSpace -value ([math]::Round(($d |  Where-Object {$_.Property -like "FreeSpace"}).Sum/1GB, 0))

#сетевые интерфейсы
$r = $null
$r = Get-WmiClass -ComputerName $ComputerName -ClassName "Win32_NetworkAdapterConfiguration" -cimSession $cimSession -PSver $PSver
$r = $r | Where-Object {($_.IPEnabled -eq $true)} | select @{Name = "IPAddress"; expression={$_.IPAddress -join ","}}, `
                                                           @{Name = "DefaultIPGateway"; expression={$_.DefaultIPGateway -join ","}}, `
                                                           @{Name = "DNSServer"; expression={$_.DNSServerSearchOrder -join ","}}, `
                                                           DHCPEnabled, `
                                                           DHCPServer
#получаем интерфейс для которого задан адрес шлюза
$ip = $r | Where-Object {($_.DefaultIPGateway -ne $null)}
#заполняем данные 
$hwr | Add-Member -Membertype NoteProperty -Name IP -value $ip.IPAddress
$hwr | Add-Member -Membertype NoteProperty -Name DHCP -value $ip.DHCPEnabled
$hwr | Add-Member -Membertype NoteProperty -Name DefaultGateway -value $ip.DefaultIPGateway
$hwr | Add-Member -Membertype NoteProperty -Name DNSServer -value $ip.DNSServer
$hwr | Add-Member -Membertype NoteProperty -Name DHCPServer -value $ip.DHCPServer

#компьютер
$r = $null
$r = Get-WmiClass -ComputerName $ComputerName -ClassName "Win32_ComputerSystem" -cimSession $cimSession -PSver $PSver
$r = $r | select Name, Domain, Model, Manufacturer, UserName, @{Name="ComputerMemory"; Expression={[math]::Round($_.TotalPhysicalMemory/1GB, 0)}}
#заполняем данные
$hwr | Add-Member -Membertype NoteProperty -Name Model -value $r.Model
$hwr | Add-Member -Membertype NoteProperty -Name Manufacturer -value $r.Manufacturer
$hwr | Add-Member -Membertype NoteProperty -Name Domain -value $r.Domain
$hwr | Add-Member -Membertype NoteProperty -Name UserName -value $r.UserName
$hwr | Add-Member -Membertype NoteProperty -Name ComputerMemory -value $r.ComputerMemory

#получаем версию ОС
$r = $null
if ($LocalComputer)
    {$r = Invoke-Command -ScriptBlock {Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\" | Select-Object ProductName, DisplayVersion, CurrentBuild}}
    else
    {$r = Invoke-Command -ComputerName $ComputerName -ScriptBlock {Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\" | Select-Object ProductName, DisplayVersion, CurrentBuild}}  
$hwr | Add-Member -Membertype NoteProperty -Name OS -value $r.ProductName
$hwr | Add-Member -Membertype NoteProperty -Name OSVersion -value $r.DisplayVersion
$hwr | Add-Member -Membertype NoteProperty -Name OSBuild -value $r.CurrentBuild

#биос
$r = $null
$r = Get-WmiClass -ComputerName $ComputerName -ClassName "Win32_BIOS" -cimSession $cimSession -PSver $PSver
$r = $r | select SerialNumber, SMBIOSBIOSVersion, Manufacturer, Version
$hwr | Add-Member -Membertype NoteProperty -Name SerialNumber -value $r.SerialNumber
$hwr | Add-Member -Membertype NoteProperty -Name BIOSSMBIOSBIOSVersion -value $r.SMBIOSBIOSVersion
$hwr | Add-Member -Membertype NoteProperty -Name BIOSManufacturer -value $r.Manufacturer
$hwr | Add-Member -Membertype NoteProperty -Name Version -value $r.Version

#процессор
$r = $null
$r = Get-WmiClass -ComputerName $ComputerName -ClassName "Win32_Processor" -cimSession $cimSession -PSver $PSver
$r = $r | select -ExcludeProperty "CIM*" | select Name, MaxClockSpeed | Group-Object Name -NoElement
$hwr | Add-Member -Membertype NoteProperty -Name CPUName -value $r.Name
$hwr | Add-Member -Membertype NoteProperty -Name CPUCount -value $r.Count

#материнская плата
$r = $null
$r = Get-WmiClass -ComputerName $ComputerName -ClassName "Win32_BaseBoard" -cimSession $cimSession -PSver $PSver
$r = $r | select-object Manufacturer, Product
$hwr | Add-Member -Membertype NoteProperty -Name MBProduct -value $r.Product
$hwr | Add-Member -Membertype NoteProperty -Name MBManufacturer -value $r.Manufacturer

#дата сбора и тип информации
$hwr | Add-Member -Membertype NoteProperty -Name CollectionDate -value $collection_date
$hwr | Add-Member -Membertype NoteProperty -Name TypeInfo -value $CurrnetTypeInfo
         
$r = [pscustomobject]@{Type = $CurrnetTypeInfo; Data = $hwr | select ComputerName, Model, OS, OSVersion, OSBuild, Manufacturer, Domain, SerialNumber, UserName, `
                                                                     IP, DHCP, DHCPServer, DefaultGateway, DNSServer, CPUName, CPUCount, ComputerMemory, HDDSize, HDDFreeSpace, `
                                                                     MBProduct, MBManufacturer, BIOSSMBIOSBIOSVersion, BIOSManufacturer, BIOSVersion, CollectionDate, TypeInfo}
return $r