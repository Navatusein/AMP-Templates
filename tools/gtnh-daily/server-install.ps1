# First install only: unpacks a stable GTNH server pack that the updater then moves to daily.
# Skipped when server files already exist (e.g. an existing server was uploaded).
$ProgressPreference = 'SilentlyContinue';
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
Set-Location -Path '{{$FullBaseDir}}';
if (Test-Path 'lwjgl3ify-forgePatches.jar') { Write-Output 'Server files already present. Skipping base pack install'; exit 0 };
$Ver = '{{InitialConfigVersion}}';
$Url = '{{BasePackUrl}}';
if ($Url -eq '') {
if ($Ver -match '^\d+\.\d+\.\d+$') { $Url = 'https://downloads.gtnewhorizons.com/ServerPacks/GT_New_Horizons_' + $Ver + '_Server_Java_17-25.zip' } else { Write-Output ('Initial Config Version ' + $Ver + ' is not a stable release, so no server pack can be downloaded for it. Set Base Server Pack URL or upload the server files. Aborting'); exit 1 };
};
Write-Output ('Downloading GTNH server pack from ' + $Url);
Remove-Item base-pack.zip -Force -ErrorAction SilentlyContinue;
try { Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile base-pack.zip -ErrorAction Stop } catch { Write-Output 'Server pack download failed. Aborting'; exit 1 };
Expand-Archive -Path base-pack.zip -DestinationPath . -Force;
Remove-Item base-pack.zip -Force -ErrorAction SilentlyContinue;
Write-Output 'GTNH server pack installed';
