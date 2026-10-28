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
if (-not (Test-Path (Join-Path $D '.gtnh-daily-updater.json'))) {
Write-Output 'Initializing gtnh-daily-updater (config version {{InitialConfigVersion}}, mode {{PackMode}})';
& $U init --instance-dir $D --side server --mode '{{PackMode}}' --config '{{InitialConfigVersion}}';
if ($LASTEXITCODE -ne 0) { Write-Output 'gtnh-daily-updater init failed. Aborting'; exit 1 };
};
$UpdateArgs = @('update', '--instance-dir', $D, '--cache-dir', (Join-Path '{{$FullRootDir}}' 'updater\cache'), '--concurrency', '{{Concurrency}}');
if ('{{ModVersions}}' -eq 'latest') { $UpdateArgs += '--latest' };
& $U @UpdateArgs;
if ($LASTEXITCODE -ne 0) { Write-Output 'gtnh-daily-updater update failed. Aborting'; exit 1 };
