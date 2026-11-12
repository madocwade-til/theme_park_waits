# Optional: run this yourself to register the collector with Windows Task Scheduler.
param([string]$PythonPath = "python")
$ErrorActionPreference = "Stop"
$PythonExe = (Get-Command $PythonPath).Source
$Main = Join-Path $PSScriptRoot "main.py"
$Config = Join-Path $PSScriptRoot "config.json"
$Action = New-ScheduledTaskAction -Execute $PythonExe `
    -Argument ('"{0}" once --config "{1}"' -f $Main, $Config) `
    -WorkingDirectory $PSScriptRoot
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) `
    -RepetitionInterval (New-TimeSpan -Minutes 5)
$Settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew `
    -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "ThemeParkWaitsCollector" -Action $Action `
    -Trigger $Trigger -Settings $Settings `
    -Description "Collect wait times every five minutes. Powered by Queue-Times.com."
