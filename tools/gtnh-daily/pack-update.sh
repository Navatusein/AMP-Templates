# Runs gtnh-daily-updater: init once (records the installed pack), then update to the latest daily/experimental.
U="{{$FullRootDir}}updater/gtnh-daily-updater";
D="{{$FullBaseDir}}";
if ! command -v git >/dev/null 2>&1; then echo "git is required to merge pack config changes but was not found. Aborting"; exit 1; fi;
if [[ ! -x "$U" ]]; then echo "gtnh-daily-updater is missing. Aborting"; exit 1; fi;
export GITHUB_TOKEN="{{GithubToken}}";
if [[ ! -f "${D}.gtnh-daily-updater.json" ]]; then
Cfg="{{InitialConfigVersion}}";
if [[ -z "$Cfg" && -f "{{$FullRootDir}}initial-config.txt" ]]; then Cfg=$(tr -d "[:space:]" < "{{$FullRootDir}}initial-config.txt"); fi;
if [[ -z "$Cfg" ]]; then echo "Config version of the installed server is unknown. Set Initial Config Version to the exact config version of the uploaded server. Aborting"; exit 1; fi;
echo "Initializing gtnh-daily-updater (config version $Cfg, mode {{PackMode}})";
"$U" init --instance-dir "$D" --side server --mode "{{PackMode}}" --config "$Cfg" || { echo "gtnh-daily-updater init failed. Aborting"; exit 1; };
fi;
Extra=();
if [[ "{{ModVersions}}" == "latest" ]]; then Extra+=(--latest); fi;
"$U" update --instance-dir "$D" --cache-dir "{{$FullRootDir}}updater/cache" --concurrency "{{Concurrency}}" "${Extra[@]}" || { echo "gtnh-daily-updater update failed. Aborting"; exit 1; };
