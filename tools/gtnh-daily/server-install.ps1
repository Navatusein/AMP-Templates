# First install only: unpacks a GTNH server pack that the updater then keeps on daily/experimental.
# Source: Base Server Pack URL, else the stable pack when Initial Config Version is x.y.z,
# else a daily build from GTNH-Daily-Builds (Daily Build Tag or the latest) with its config version taken from the build manifest.
# The config version is saved to <root>\initial-config.txt for the Pack Update stage.
# Skipped when server files already exist (e.g. an existing server was uploaded).
$ProgressPreference = 'SilentlyContinue';
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
Set-Location -Path '{{$FullBaseDir}}';
if (Test-Path 'lwjgl3ify-forgePatches.jar') { Write-Output 'Server files already present. Skipping base pack install'; exit 0 };
$Ver = '{{InitialConfigVersion}}';
$Url = '{{BasePackUrl}}';
$CfgFile = Join-Path '{{$FullRootDir}}' 'initial-config.txt';
if ($Url -ne '') {
if ($Ver -eq '') { Write-Output 'Base Server Pack URL is set, so Initial Config Version must be set to the config version of that pack. Aborting'; exit 1 };
} elseif ($Ver -match '^\d+\.\d+\.\d+$') { $Url = 'https://downloads.gtnewhorizons.com/ServerPacks/GT_New_Horizons_' + $Ver + '_Server_Java_17-25.zip'
} elseif ($Ver -ne '') { Write-Output ('Initial Config Version ' + $Ver + ' is not a stable release, so no server pack can be downloaded for it. Clear it to install a daily build, set Base Server Pack URL or upload the server files. Aborting'); exit 1
} else {
$Tag = '{{DailyBuildTag}}';
$Headers = @{ 'User-Agent' = 'AMP-gtnh-daily' };
if ('{{GithubToken}}' -ne '') { $Headers['Authorization'] = 'Bearer {{GithubToken}}' };
if ($Tag -eq '') { $Api = 'https://api.github.com/repos/GTNewHorizons/GTNH-Daily-Builds/releases/latest' } else { $Api = 'https://api.github.com/repos/GTNewHorizons/GTNH-Daily-Builds/releases/tags/' + $Tag.Replace('+', '%2B') };
try { $Release = Invoke-RestMethod -UseBasicParsing -Headers $Headers -Uri $Api -ErrorAction Stop } catch { Write-Output ('Failed to query GTNH daily build ' + $Tag + ' (empty = latest). Aborting'); exit 1 };
$Tag = $Release.tag_name;
$Pack = $Release.assets | Where-Object { $_.name -match '-server-java17-\d+\.zip$' } | Select-Object -First 1;
$Manifest = $Release.assets | Where-Object { $_.name -like '*-manifest.json.zip' } | Select-Object -First 1;
if ([string]::IsNullOrEmpty($Tag) -or $null -eq $Pack -or $null -eq $Manifest) { Write-Output 'Daily build has no Java 17+ server pack or manifest. Aborting'; exit 1 };
$Url = $Pack.browser_download_url;
Remove-Item build-manifest.zip, build-manifest -Recurse -Force -ErrorAction SilentlyContinue;
try { Invoke-WebRequest -UseBasicParsing -Uri $Manifest.browser_download_url -OutFile build-manifest.zip -ErrorAction Stop } catch { Write-Output 'Daily build manifest download failed. Aborting'; exit 1 };
Expand-Archive -Path build-manifest.zip -DestinationPath build-manifest -Force;
$Ver = (Get-Content -Raw (Get-ChildItem build-manifest -Recurse -Filter '*.json' | Select-Object -First 1).FullName | ConvertFrom-Json).config;
Remove-Item build-manifest.zip, build-manifest -Recurse -Force -ErrorAction SilentlyContinue;
if ([string]::IsNullOrEmpty($Ver)) { Write-Output ('Could not read the config version from the manifest of ' + $Tag + '. Aborting'); exit 1 };
Write-Output ('Using GTNH daily build ' + $Tag + ' (config version ' + $Ver + ')');
};
Write-Output ('Downloading GTNH server pack from ' + $Url);
Remove-Item base-pack.zip -Force -ErrorAction SilentlyContinue;
try { Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile base-pack.zip -ErrorAction Stop } catch { Write-Output 'Server pack download failed. Aborting'; exit 1 };
try { Expand-Archive -Path base-pack.zip -DestinationPath . -Force -ErrorAction Stop } catch { Write-Output 'Failed to extract server pack. Aborting'; exit 1 };
Remove-Item base-pack.zip -Force -ErrorAction SilentlyContinue;
Set-Content -Path $CfgFile -Value $Ver -Encoding ASCII;
Write-Output ('GTNH server pack installed (config version ' + $Ver + ')');
