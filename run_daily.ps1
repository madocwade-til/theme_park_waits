$ErrorActionPreference = "Stop"

$projectRoot = $PSScriptRoot
$pythonExe = Join-Path $projectRoot ".venv\Scripts\python.exe"
$dbtExe = 'C:\Users\MadocWade\AppData\Local\Microsoft\WinGet\Packages\dbtLabs.dbt_Microsoft.Winget.Source_8wekyb3d8bbwe\dbt.exe'
$uploadScript = Join-Path $projectRoot "python\upload_sqlite.py"

Set-Location $projectRoot
& $pythonExe $uploadScript
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Set-Location (Join-Path $projectRoot "dbt")
& $dbtExe build
exit $LASTEXITCODE