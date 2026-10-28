# Runs gtnh-daily-updater: init once (records the installed pack), then update to the latest daily/experimental.
U="{{$FullRootDir}}updater/gtnh-daily-updater";
D="{{$FullBaseDir}}";
if ! command -v git >/dev/null 2>&1; then echo "git is required to merge pack config changes but was not found. Aborting"; exit 1; fi;
if [[ ! -x "$U" ]]; then echo "gtnh-daily-updater is missing. Aborting"; exit 1; fi;
export GITHUB_TOKEN="{{GithubToken}}";
# One log per AMP update in <root>/updater/logs; the updater appends its own output, stderr (fatal errors) is teed in.
mkdir -p "{{$FullRootDir}}updater/logs";
Log="{{$FullRootDir}}updater/logs/update-$(date +%Y-%m-%d_%H-%M-%S).log";
Tag="{{DailyBuildTag}}";
echo "AMP update: mode {{PackMode}}, daily build ${Tag:-latest}, mod versions {{ModVersions}}" >> "$Log";
echo "Update log: $Log";
if [[ ! -f "${D}.gtnh-daily-updater.json" ]]; then
Cfg="{{InitialConfigVersion}}";
if [[ -z "$Cfg" && -f "{{$FullRootDir}}initial-config.txt" ]]; then Cfg=$(tr -d "[:space:]" < "{{$FullRootDir}}initial-config.txt"); fi;
if [[ -z "$Cfg" ]]; then echo "Config version of the installed server is unknown. Set Initial Config Version to the exact config version of the uploaded server. Aborting"; exit 1; fi;
echo "Initializing gtnh-daily-updater (config version $Cfg, mode {{PackMode}})";
"$U" init --instance-dir "$D" --side server --mode "{{PackMode}}" --config "$Cfg" --log-file "$Log" 2> >(tee -a "$Log" >&2) || { echo "gtnh-daily-updater init failed. Aborting" | tee -a "$Log"; exit 1; };
fi;
Extra=();
if [[ "{{ModVersions}}" == "latest" ]]; then Extra+=(--latest); fi;
if [[ -n "$Tag" ]]; then echo "Updating to daily build $Tag"; Extra+=(--build "$Tag"); fi;
"$U" update --instance-dir "$D" --cache-dir "{{$FullRootDir}}updater/cache" --concurrency "{{Concurrency}}" --log-file "$Log" "${Extra[@]}" 2> >(tee -a "$Log" >&2) || { echo "gtnh-daily-updater update failed. Aborting" | tee -a "$Log"; exit 1; };
