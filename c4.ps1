# Load machine list
$computers = Get-Content E:\Harshitha\cdrivespace\machines.txt

# Timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"   #newly

# Region-based arrays
$pingable_register_nam = @()    #newly
$pingable_register_ap = @()     #newly
$pingable_register_eu = @()     #newly
$offline_register = @{}         #newly

# Define output paths
$outputPath = "E:\Harshitha\cdrivespace\Output.txt"         #newly
$tempPath   = "E:\Harshitha\cdrivespace\Output_temp.txt"    #newly

# Clear temp file and write header
Clear-Content $tempPath -ErrorAction SilentlyContinue       #newly
Add-Content -Path $tempPath -Value "=== C Drive Report ===" #newly
Add-Content -Path $tempPath -Value "Generated: $timestamp"  #newly
Add-Content -Path $tempPath -Value ""                       #newly

# Classify computers by region
foreach($register in $computers){
    if(Test-Connection $register -Count 1 -Quiet){
        if ($register -like "*JP*") {
            $pingable_register_ap += $register
        }
        elseif ($register -like "*US*" -or $register -like "*CA*") {
            $pingable_register_nam += $register
        }
        else {
            $pingable_register_eu += $register
        }
    }
    else {
        $offline_register_ht = @{
            "hostname" = "$register";
            "status" = "offline";
            "timestamp" = $timestamp
        }
        $offline_register.Add($register, $offline_register_ht)
    }
}

# Export offline machines
$offline_register | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath "E:\Harshitha\cdrivespace\offline.json" -Encoding utf8  #newly

# Region credentials
# EU
$Username = "SVC_EU"
$Password = "ADMIN"
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$MySecureCreds_EU = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $pass

# AP
$Username = "ap\svc_AP"
$Password = "ADMIN2"
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$MySecureCreds_AP = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $pass

# NAM
$Username = "AM\SVC_NAM"
$Password = "aDMIN3"
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$MySecureCreds_NAM = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $pass

# Disk check function
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
                Add-Content -Path $tempPath -Value "[$ComputerName] Used: $used GB | Free: $free GB | Total: $total GB | Status: Low Disk Space"  #newly
            } else {
                Add-Content -Path $tempPath -Value "[$ComputerName] Used: $used GB | Free: $free GB | Total: $total GB | Status: Healthy"        #newly
            }
        } else {
            Add-Content -Path $tempPath -Value "[$ComputerName] Drive Not Found"   #newly
        }
    }
    catch {
        Add-Content -Path $tempPath -Value "[$ComputerName] Error: $($_.Exception.Message)"   #newly
    }
}

# Run checks for each region
foreach ($computer in $pingable_register_nam) {
    Write-Host "Checking $computer with NAM credentials"
    Check-DiskSpace -ComputerName $computer -Credential $MySecureCreds_NAM
}

foreach ($computer in $pingable_register_ap) {
    Write-Host "Checking $computer with AP credentials"
    Check-DiskSpace -ComputerName $computer -Credential $MySecureCreds_AP
}

foreach ($computer in $pingable_register_eu) {
    Write-Host "Checking $computer with EU credentials"
    Check-DiskSpace -ComputerName $computer -Credential $MySecureCreds_EU
}

# Final overwrite to avoid file lock issue
Copy-Item -Path $tempPath -Destination $outputPath -Force   #newly
