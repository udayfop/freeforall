# Load machine list
$computers = Get-Content E:\Harshitha\cdrivespace\machines.txt

# Load timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Region-based groupings
$pingable_register_nam = @()
$pingable_register_ap = @()
$pingable_register_eu = @()
$offline_register = @{}

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
        $offline_register.Add($register,$offline_register_ht)
    }
}

$offline_register | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath "E:\Harshitha\cdrivespace\offline.json" -Encoding utf8

# EU login
$Username = "abc"
$Password = "Admin"
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$MySecureCreds_EU = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$pass

# AP login
$Username = "abc"
$Password = "Admin"
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$MySecureCreds_AP = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$pass

# NAM login
$Username = "abc"
$Password = "Admin"
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$MySecureCreds_NAM = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$pass

# Define output paths
$outputPath = "E:\Harshitha\cdrivespace\Output.txt"        # existing
$tempPath   = "E:\Harshitha\cdrivespace\Output_temp.txt"    #add

# Clear temp file and write header
Clear-Content $tempPath -ErrorAction SilentlyContinue       #add
Add-Content -Path $tempPath -Value "Generated: $timestamp"  #add
Add-Content -Path $tempPath -Value ""                       #add

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
                Add-Content -Path $tempPath -Value "[$ComputerName] Used: $used GB | Free: $free GB | Total: $total GB | Status: Low Disk Space"   #add
            } else {
                Add-Content -Path $tempPath -Value "[$ComputerName] Used: $used GB | Free: $free GB | Total: $total GB | Status: Healthy"         #add
            }
        } else {
            Add-Content -Path $tempPath -Value "[$ComputerName] Drive not found."      #add
        }
    }
    catch {
        Add-Content -Path $tempPath -Value "[$ComputerName] Error: $($_.Exception.Message)"    #add
    }
}

# Loop through NAM region
foreach ($computer in $pingable_register_nam) {
    Write-Host
