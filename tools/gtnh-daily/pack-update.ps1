# Runs gtnh-daily-updater: init once (records the installed pack), then update to the latest daily/experimental.
$U = Join-Path '{{$FullRootDir}}' 'updater\gtnh-daily-updater.exe';
$D = ('{{$FullBaseDir}}').TrimEnd('\', '/');
if ($null -eq (Get-Command git -ErrorAction SilentlyContinue)) { Write-Output 'git is required to merge pack config changes but was not found. Install Git for Windows. Aborting'; exit 1 };
if (-not (Test-Path $U)) { Write-Output 'gtnh-daily-updater is missing. Aborting'; exit 1 };
$env:GITHUB_TOKEN = '{{GithubToken}}';
# GTNH quest configs have ~135-char relative paths; let git exceed MAX_PATH (process-scoped, git 2.31+).
$env:GIT_CONFIG_COUNT = '1';
$env:GIT_CONFIG_KEY_0 = 'core.longpaths';
$env:GIT_CONFIG_VALUE_0 = 'true';
# One log per AMP update in <root>\updater\logs; the updater appends its own output, stderr (fatal errors) is copied in.
$LogDir = Join-Path '{{$FullRootDir}}' 'updater\logs';
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null;
$Log = Join-Path $LogDir ('update-' + (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss') + '.log');
$Tag = '{{DailyBuildTag}}';
Add-Content -Path $Log -Value ('AMP update: mode {{PackMode}}, daily build ' + $(if ($Tag -eq '') { 'latest' } else { $Tag }) + ', mod versions {{ModVersions}}');
Write-Output ('Update log: ' + $Log);
function Invoke-Updater { & $U @args --log-file $Log 2>&1 | ForEach-Object { $Line = [string]$_; Write-Output $Line; if ($_ -is [System.Management.Automation.ErrorRecord]) { Add-Content -Path $Log -Value $Line } } };
if (-not (Test-Path (Join-Path $D '.gtnh-daily-updater.json'))) {
$Cfg = '{{InitialConfigVersion}}';
$CfgFile = Join-Path '{{$FullRootDir}}' 'initial-config.txt';
if ($Cfg -eq '' -and (Test-Path $CfgFile)) { $Cfg = (Get-Content -Raw $CfgFile).Trim() };
if ($Cfg -eq '') { Write-Output 'Config version of the installed server is unknown. Set Initial Config Version to the exact config version of the uploaded server. Aborting'; exit 1 };
Write-Output ('Initializing gtnh-daily-updater (config version ' + $Cfg + ', mode {{PackMode}})');
Invoke-Updater init --instance-dir $D --side server --mode '{{PackMode}}' --config $Cfg;
if ($LASTEXITCODE -ne 0) { Write-Output 'gtnh-daily-updater init failed. Aborting'; Add-Content -Path $Log -Value 'gtnh-daily-updater init failed'; exit 1 };
};
$UpdateArgs = @('update', '--instance-dir', $D, '--cache-dir', (Join-Path '{{$FullRootDir}}' 'updater\cache'), '--concurrency', '{{Concurrency}}');
if ('{{ModVersions}}' -eq 'latest') { $UpdateArgs += '--latest' };
if ($Tag -ne '') { Write-Output ('Updating to daily build ' + $Tag); $UpdateArgs += @('--build', $Tag) };
Invoke-Updater @UpdateArgs;
if ($LASTEXITCODE -ne 0) { Write-Output 'gtnh-daily-updater update failed. Aborting'; Add-Content -Path $Log -Value 'gtnh-daily-updater update failed'; exit 1 };
