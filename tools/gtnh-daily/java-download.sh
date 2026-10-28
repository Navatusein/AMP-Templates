# Installs Eclipse Temurin JRE into <root>/java when "Specific instance version" is selected.
for Tool in wget jq tar; do if ! command -v "$Tool" >/dev/null 2>&1; then echo "$Tool is required but was not found. Aborting"; exit 1; fi; done;
cd "{{$FullRootDir}}" || exit 1;
case "$(uname -m)" in x86_64) Arch=x64;; aarch64) Arch=aarch64;; *) echo "Unsupported architecture $(uname -m)"; exit 1;; esac;
Installed="";
if [[ -x java/bin/java ]]; then Installed=$(java/bin/java --version 2>&1 | grep -oE "Temurin-[^ ]+" | head -n1 | cut -d- -f2); fi;
Latest=$(wget -qO- "https://api.adoptium.net/v3/assets/latest/{{SpecificInstanceJavaVersion}}/hotspot?architecture=$Arch&image_type=jre&os=linux&vendor=eclipse" | jq -r ".[0].version.openjdk_version" | sed "s/-LTS$//");
if [[ -z "$Latest" || "$Latest" == "null" ]]; then echo "Could not get the latest Eclipse Temurin {{SpecificInstanceJavaVersion}} version. Aborting"; exit 1; fi;
if [[ "$Installed" == "$Latest" ]]; then echo "Eclipse Temurin Java $Latest already installed. Skipping"; exit 0; fi;
rm -f java.tar.gz;
wget -qO java.tar.gz "https://api.adoptium.net/v3/binary/latest/{{SpecificInstanceJavaVersion}}/ga/linux/$Arch/jre/hotspot/normal/eclipse" || { echo "Download failed from the Eclipse Temurin CDN. Aborting"; exit 1; };
mkdir -p java && rm -rf java/* && tar -xzf java.tar.gz -C java --strip-components=1 && rm -f java.tar.gz && chmod +x java/bin/java && echo "Eclipse Temurin Java $Latest installed";
