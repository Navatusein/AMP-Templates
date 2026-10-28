# Installs Eclipse Temurin JRE into <root>\java when "Specific instance version" is selected.
$ProgressPreference = 'SilentlyContinue';
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
Set-Location -Path '{{$FullRootDir}}';
$Installed = '';
if (Test-Path 'java/bin/java.exe') { $Out = (& 'java/bin/java.exe' --version 2>&1) -join ' '; if ($Out -match 'Temurin-(\S+)') { $Installed = $Matches[1] } };
try { $Latest = ((Invoke-RestMethod -UseBasicParsing -Uri 'https://api.adoptium.net/v3/assets/latest/{{SpecificInstanceJavaVersion}}/hotspot?architecture=x64&image_type=jre&os=windows&vendor=eclipse' -ErrorAction Stop)[0].version.openjdk_version) -replace '-LTS$', '' } catch { $Latest = '' };
if ([string]::IsNullOrEmpty($Latest)) { Write-Output 'Could not get the latest Eclipse Temurin {{SpecificInstanceJavaVersion}} version. Aborting'; exit 1 };
if ($Installed -eq $Latest) { Write-Output ('Eclipse Temurin Java ' + $Latest + ' already installed. Skipping'); exit 0 };
Remove-Item java.zip -Force -ErrorAction SilentlyContinue;
try { Invoke-WebRequest -UseBasicParsing -Uri 'https://api.adoptium.net/v3/binary/latest/{{SpecificInstanceJavaVersion}}/ga/windows/x64/jre/hotspot/normal/eclipse' -OutFile java.zip -ErrorAction Stop } catch { Write-Output 'Download failed from the Eclipse Temurin CDN. Aborting'; exit 1 };
Remove-Item java-extract -Recurse -Force -ErrorAction SilentlyContinue;
Expand-Archive -Path java.zip -DestinationPath java-extract -Force;
Remove-Item java.zip -Force -ErrorAction SilentlyContinue;
Remove-Item java -Recurse -Force -ErrorAction SilentlyContinue;
Get-ChildItem -Path java-extract -Directory | Select-Object -First 1 | Move-Item -Destination java;
Remove-Item java-extract -Recurse -Force -ErrorAction SilentlyContinue;
Write-Output ('Eclipse Temurin Java ' + $Latest + ' installed');
