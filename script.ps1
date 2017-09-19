$directory = "\location\to\folder"
$logName = "logfilename"
$serviceName = "servicename"

$logFile = Join-Path $directory $logName
$service = Get-Service $serviceName
$service.Start()
$service.WaitForStatus("Running", '00:00:15')

# kick off the log monitor
$monitor = Start-Job -ScriptBlock {
    param($file)
    
    # make sure the file exists
    while(-not (Test-Path $file)){ sleep -sec 3 }
    
    # kick off the job
    Get-Content $file -wait
    
} -Name LogMonitor -Arg $logFile

while ($monitor.State -eq "Running" -and -not ($service.Status -eq "Stopped")) {
    Receive-Job -Job $monitor
    $service.Refresh()
    Start-Sleep -s 1
}
$monitor | Stop-Job | Remove-Job

# read service status log, parse last line for success/failure
$output = Get-Content $logFile | Out-String
$result = ($output.Split([Environment]::NewLine,[System.StringSplitOptions]::RemoveEmptyEntries))
$result = $result[-1]

# assert
If (-Not ($result -match "^SUCCEEDED")) {
    
}
