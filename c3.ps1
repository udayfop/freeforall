# Load machine list
$computers = Get-Content E:\Harshitha\cdrivespace\machines.txt

# Load timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"   #ADD

# Region-based groupings
$pingable_register_nam = @()    #ADD
$pingable_register_ap = @()     #ADD
$pingable_register_eu = @()     #ADD
$offline_register = @{}         #ADD

foreach($register in $computers){
    if(Test-Connection $register -Count 1 -Quiet){
        if ($register -like "*JP*") {
            $pingable_register_ap += $register   #ADD
        }
        elseif ($register -like "*US*" -or $register -like "*CA*") {
            $pingable_register_nam += $register  #ADD
        }
        else {
            $pingable_register_eu += $register   #ADD
        }
    }
    else {
        $offline_register_ht = @{
            "hostname" = "$register";
            "status" = "offline";
            "timestamp" = $timestamp
        }
        $offline_register.Add($register,$offline_register_ht)   #ADD
    }
}

$offline_register | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath "E:\Harshitha\cdrivespace\offline.json" -Encoding utf8  #ADD

# EU login
$Username = "SVC_EU"
$Password = "ADMIN"
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$MySecureCreds_EU = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$pass

# AP login
$Username = "ap\svc_AP"
$Password = "ADMIN2"
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$MySecureCreds_AP = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$pass

# NAM login
$Username = "AM\SVC_NAM"
$Password = "aDMIN3"
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$MySecureCreds_NAM = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$pass

# Clear previous output and add header
$outputPath = "E:\Harshitha\cdrivespace\Output.txt"    #REPLACE
Clear-Content $outputPath                              #REPLACE
Add-Content -Path $outputPath -Value "=== C Drive Report ==="  #REPLACE
Add-Content -Path $outputPath -Value "Generated: $timestamp"   #ADD
Add-Content -Path $outputPath -Value ""                        #ADD

# Function to check disk space with proper credentials
function Check-DiskSpace {
    param (
        [string]$ComputerName,
        [System.Management.Automation.PSCredential]$Credential
    )

    try {
        $drive = Get-WmiObject Win32_LogicalDisk -ComputerName $ComputerName -Filter "DeviceID='C:'" -Credential $Credential -ErrorAction Stop
        if ($drive) {
            $used = [math]::Round(($drive.Size - $drive.FreeSpace) / 1GB, 2)
            $free = [math]::Round(($drive.FreeSpace / 1GB), 2)
            $total = [math]::Round(($drive.Size / 1GB), 2)

            if ($free -lt 15) {
                Add-Content -Path $outputPath -Value "[$ComputerName] Used: $used GB | Free: $free GB | Total: $total GB | Status: Low Disk Space"   #REPLACE
            } else {
                Add-Content -Path $outputPath -Value "[$ComputerName] Used: $used GB | Free: $free GB | Total: $total GB | Status: Healthy"         #REPLACE
            }
        } else {
            Add-Content -Path $outputPath -Value "[$ComputerName] Drive not found."      #REPLACE
        }
    }
    catch {
        Add-Content -Path $outputPath -Value "[$ComputerName] Error: $($_.Exception.Message)"    #REPLACE
    }
}

# Loop through NAM region
foreach ($computer in $pingable_register_nam) {
    Write-Host "Checking $computer with NAM credentials"   #ADD
    Check-DiskSpace -ComputerName $computer -Credential $MySecureCreds_NAM
}

# Loop through AP region
foreach ($computer in $pingable_register_ap) {
    Write-Host "Checking $computer with AP credentials"   #ADD
    Check-DiskSpace -ComputerName $computer -Credential $MySecureCreds_AP
}

# Loop through EU region
foreach ($computer in $pingable_register_eu) {
    Write-Host "Checking $computer with EU credentials"   #ADD
    Check-DiskSpace -ComputerName $computer -Credential $MySecureCreds_EU
}
