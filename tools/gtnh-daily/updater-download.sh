# Downloads (or refreshes) the gtnh-daily-updater binary from GitHub Releases.
# Rules for these stage scripts: every command ends with ';' (or a block keyword),
# no trailing comments, because build.py joins the lines into a single bash -c argument.
for Tool in wget jq unzip; do if ! command -v "$Tool" >/dev/null 2>&1; then echo "$Tool is required but was not found. Aborting"; exit 1; fi; done;
Repo="{{UpdaterRepo}}";
Want="{{UpdaterVersion}}";
Dir="{{$FullRootDir}}updater";
mkdir -p "$Dir";
case "$(uname -m)" in x86_64) Arch=amd64;; aarch64) Arch=arm64;; *) echo "Unsupported architecture $(uname -m)"; exit 1;; esac;
Auth=();
if [[ -n "{{GithubToken}}" ]]; then Auth=(--header "Authorization: Bearer {{GithubToken}}"); fi;
if [[ -z "$Want" ]]; then Api="https://api.github.com/repos/$Repo/releases/latest"; else Api="https://api.github.com/repos/$Repo/releases/tags/$Want"; fi;
Json=$(wget -qO- "${Auth[@]}" "$Api") || { echo "Failed to query GitHub releases of $Repo. Aborting"; exit 1; };
Tag=$(echo "$Json" | jq -r ".tag_name // empty");
if [[ -z "$Tag" ]]; then echo "No release found in $Repo. Aborting"; exit 1; fi;
Url=$(echo "$Json" | jq -r --arg suffix "-linux-$Arch.zip" '.assets[] | select(.name | endswith($suffix)) | .browser_download_url' | head -n1);
Installed="";
if [[ -x "$Dir/gtnh-daily-updater" ]]; then Installed=$("$Dir/gtnh-daily-updater" --version 2>/dev/null | grep -oE "version [^ ]+" | head -n1 | cut -d" " -f2); fi;
if [[ "$Installed" == "$Tag" ]]; then echo "gtnh-daily-updater $Tag already installed. Skipping"; exit 0; fi;
if [[ -z "$Url" ]]; then echo "Release $Tag of $Repo has no linux-$Arch build. Aborting"; exit 1; fi;
rm -f "$Dir/updater.zip";
wget -qO "$Dir/updater.zip" "$Url" || { echo "gtnh-daily-updater download failed. Aborting"; exit 1; };
unzip -oq "$Dir/updater.zip" -d "$Dir" || { echo "Failed to extract gtnh-daily-updater (is unzip installed?). Aborting"; exit 1; };
rm -f "$Dir/updater.zip";
chmod +x "$Dir/gtnh-daily-updater";
echo "gtnh-daily-updater $Tag installed";
