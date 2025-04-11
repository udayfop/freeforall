$computers = Get-Content E:\Harshitha\cdrivespace\machines.txt

# Source credentials
. E:\Harshitha\test\creds.ps1

# Clear previous CSV content
Clear-Content "E:\Harshitha\cdrivespace\Output.csv"

# Header for CSV
Add-Content -Path E:\Harshitha\cdrivespace\Output.csv -Value "Computer,Used(GB),Free(GB),Total(GB),Status"

# Secure credentials
$pass = ConvertTo-SecureString -AsPlainText $password_global -Force
$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $user_global, $pass

foreach ($computer in $computers) {
    if (Test-Connection -ComputerName $computer -Count 1 -Quiet) {
        Write-Host "✅ $computer is reachable"
        
        try {
            $drive = Get-WmiObject Win32_LogicalDisk -ComputerName $computer -Filter "DeviceID='C:'" -Credential $Cred -ErrorAction Stop

            if ($drive) {
                $used = [math]::Round(($drive.Size - $drive.FreeSpace) / 1GB, 2)
                $free = [math]::Round(($drive.FreeSpace / 1GB), 2)
                $total = [math]::Round(($drive.Size / 1GB), 2)

                if ($free -lt 15) {
                    Add-Content -Path E:\Harshitha\cdrivespace\Output.csv -Value "$computer,$used,$free,$total,Low Disk Space"
                } else {
                    Add-Content -Path E:\Harshitha\cdrivespace\Output.csv -Value "$computer,$used,$free,$total,Healthy"
                }
            } else {
                Add-Content -Path E:\Harshitha\cdrivespace\Output.csv -Value "$computer,,, ,Drive Not Found"
            }
        } catch {
            Add-Content -Path E:\Harshitha\cdrivespace\Output.csv -Value "$computer,,, ,Error: $($_.Exception.Message)"
        }
    } else {
        Write-Host "❌ $computer not reachable"
        Add-Content -Path E:\Harshitha\cdrivespace\Output.csv -Value "$computer,,, ,Unreachable"
    }
}
