# First install only: unpacks a stable GTNH server pack that the updater then moves to daily.
# Skipped when server files already exist (e.g. an existing server was uploaded).
for Tool in wget unzip; do if ! command -v "$Tool" >/dev/null 2>&1; then echo "$Tool is required but was not found. Aborting"; exit 1; fi; done;
cd "{{$FullBaseDir}}" || exit 1;
if [[ -f lwjgl3ify-forgePatches.jar ]]; then echo "Server files already present. Skipping base pack install"; exit 0; fi;
Ver="{{InitialConfigVersion}}";
Url="{{BasePackUrl}}";
if [[ -z "$Url" ]]; then
if [[ "$Ver" =~ ^[0-9]+[.][0-9]+[.][0-9]+$ ]]; then Url="https://downloads.gtnewhorizons.com/ServerPacks/GT_New_Horizons_${Ver}_Server_Java_17-25.zip"; else echo "Initial Config Version $Ver is not a stable release, so no server pack can be downloaded for it. Set Base Server Pack URL or upload the server files. Aborting"; exit 1; fi;
fi;
echo "Downloading GTNH server pack from $Url";
rm -f base-pack.zip;
wget -qO base-pack.zip "$Url" || { echo "Server pack download failed. Aborting"; exit 1; };
unzip -oq base-pack.zip -d . || { echo "Failed to extract server pack (is unzip installed?). Aborting"; exit 1; };
rm -f base-pack.zip;
echo "GTNH server pack installed";
