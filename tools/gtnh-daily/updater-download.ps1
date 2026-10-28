# Downloads (or refreshes) the gtnh-daily-updater binary from GitHub Releases.
# AMP placeholders go in single quotes: Windows paths end with '\', which must never sit before a double quote.
$ProgressPreference = 'SilentlyContinue';
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
$Repo = '{{UpdaterRepo}}';
$Want = '{{UpdaterVersion}}';
$Token = '{{GithubToken}}';
$Dir = Join-Path '{{$FullRootDir}}' 'updater';
New-Item -ItemType Directory -Force -Path $Dir | Out-Null;
$Headers = @{ 'User-Agent' = 'AMP-gtnh-daily' };
if ($Token -ne '') { $Headers['Authorization'] = 'Bearer ' + $Token };
if ($Want -eq '') { $Api = 'https://api.github.com/repos/' + $Repo + '/releases/latest' } else { $Api = 'https://api.github.com/repos/' + $Repo + '/releases/tags/' + $Want };
try { $Release = Invoke-RestMethod -UseBasicParsing -Headers $Headers -Uri $Api -ErrorAction Stop } catch { Write-Output ('Failed to query GitHub releases of ' + $Repo + '. Aborting'); exit 1 };
$Tag = $Release.tag_name;
if ([string]::IsNullOrEmpty($Tag)) { Write-Output ('No release found in ' + $Repo + '. Aborting'); exit 1 };
$Exe = Join-Path $Dir 'gtnh-daily-updater.exe';
$Installed = '';
if (Test-Path $Exe) { $Out = (& $Exe --version 2>$null) -join ' '; if ($Out -match 'version\s+(\S+)') { $Installed = $Matches[1] } };
if ($Installed -eq $Tag) { Write-Output ('gtnh-daily-updater ' + $Tag + ' already installed. Skipping'); exit 0 };
$Asset = $Release.assets | Where-Object { $_.name -like '*-windows-amd64.zip' } | Select-Object -First 1;
if ($null -eq $Asset) { Write-Output ('Release ' + $Tag + ' of ' + $Repo + ' has no windows-amd64 build. Aborting'); exit 1 };
$Zip = Join-Path $Dir 'updater.zip';
try { Invoke-WebRequest -UseBasicParsing -Uri $Asset.browser_download_url -OutFile $Zip -ErrorAction Stop } catch { Write-Output 'gtnh-daily-updater download failed. Aborting'; exit 1 };
Expand-Archive -Path $Zip -DestinationPath $Dir -Force;
Remove-Item $Zip -Force -ErrorAction SilentlyContinue;
Write-Output ('gtnh-daily-updater ' + $Tag + ' installed');
