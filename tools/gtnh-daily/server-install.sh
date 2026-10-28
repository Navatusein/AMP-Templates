# First install only: unpacks a GTNH server pack that the updater then keeps on daily/experimental.
# Source: Base Server Pack URL, else the stable pack when Initial Config Version is x.y.z,
# else a daily build from GTNH-Daily-Builds (Daily Build Tag or the latest) with its config version taken from the build manifest.
# The config version is saved to <root>/initial-config.txt for the Pack Update stage.
# Skipped when server files already exist (e.g. an existing server was uploaded).
for Tool in wget jq unzip; do if ! command -v "$Tool" >/dev/null 2>&1; then echo "$Tool is required but was not found. Aborting"; exit 1; fi; done;
cd "{{$FullBaseDir}}" || exit 1;
if [[ -f lwjgl3ify-forgePatches.jar ]]; then echo "Server files already present. Skipping base pack install"; exit 0; fi;
Ver="{{InitialConfigVersion}}";
Url="{{BasePackUrl}}";
CfgFile="{{$FullRootDir}}initial-config.txt";
if [[ -n "$Url" ]]; then
if [[ -z "$Ver" ]]; then echo "Base Server Pack URL is set, so Initial Config Version must be set to that pack's config version. Aborting"; exit 1; fi;
elif [[ "$Ver" =~ ^[0-9]+[.][0-9]+[.][0-9]+$ ]]; then Url="https://downloads.gtnewhorizons.com/ServerPacks/GT_New_Horizons_${Ver}_Server_Java_17-25.zip";
elif [[ -n "$Ver" ]]; then echo "Initial Config Version $Ver is not a stable release, so no server pack can be downloaded for it. Clear it to install a daily build, set Base Server Pack URL or upload the server files. Aborting"; exit 1;
else
Tag="{{DailyBuildTag}}";
Auth=();
if [[ -n "{{GithubToken}}" ]]; then Auth=(--header "Authorization: Bearer {{GithubToken}}"); fi;
if [[ -z "$Tag" ]]; then Api="https://api.github.com/repos/GTNewHorizons/GTNH-Daily-Builds/releases/latest"; else Api="https://api.github.com/repos/GTNewHorizons/GTNH-Daily-Builds/releases/tags/${Tag//+/%2B}"; fi;
Json=$(wget -qO- "${Auth[@]}" "$Api") || { echo "Failed to query GTNH daily build ${Tag:-latest}. Aborting"; exit 1; };
Tag=$(echo "$Json" | jq -r ".tag_name // empty");
Url=$(echo "$Json" | jq -r '.assets[] | select(.name | test("-server-java17-[0-9]+[.]zip$")) | .browser_download_url' | head -n1);
ManifestUrl=$(echo "$Json" | jq -r '.assets[] | select(.name | endswith("-manifest.json.zip")) | .browser_download_url' | head -n1);
if [[ -z "$Tag" || -z "$Url" || -z "$ManifestUrl" ]]; then echo "Daily build ${Tag:-latest} has no Java 17+ server pack or manifest. Aborting"; exit 1; fi;
rm -f build-manifest.zip;
wget -qO build-manifest.zip "$ManifestUrl" || { echo "Daily build manifest download failed. Aborting"; exit 1; };
Ver=$(unzip -p build-manifest.zip | jq -r ".config // empty");
rm -f build-manifest.zip;
if [[ -z "$Ver" ]]; then echo "Could not read the config version from the manifest of $Tag. Aborting"; exit 1; fi;
echo "Using GTNH daily build $Tag (config version $Ver)";
fi;
echo "Downloading GTNH server pack from $Url";
rm -f base-pack.zip;
wget -qO base-pack.zip "$Url" || { echo "Server pack download failed. Aborting"; exit 1; };
unzip -oq base-pack.zip -d . || { echo "Failed to extract server pack. Aborting"; exit 1; };
rm -f base-pack.zip;
echo "$Ver" > "$CfgFile";
echo "GTNH server pack installed (config version $Ver)";
