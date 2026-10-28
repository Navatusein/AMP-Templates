# AMP-Templates

Custom [AMP](https://cubecoders.com/AMP) Generic module templates.

## Adding this repository to AMP

1. In ADS open **Configuration → Instance Deployment → Configuration Repositories**.
2. Add `Navatusein/AMP-Templates:main`.
3. Click **Fetch Latest** on the Instances page. The templates appear in the application list when creating an instance.

## Templates

### GT New Horizons (Daily) — `gtnh-daily`

A GregTech: New Horizons server that stays on the **daily** (or **experimental**) build.
Updates are done by [gtnh-daily-updater](https://github.com/Caedis/gtnh-daily-updater):
pressing **Update** in AMP (or a scheduled *Update the application* task) moves the server
to the newest daily build, downloading changed mods and merging pack config changes with
git while keeping your own config edits (on a conflicting line the pack wins).

What the **Update** button does:

| Stage | When | What |
|---|---|---|
| Java Download | Java Version = *Specific instance version* (default) | Installs Eclipse Temurin JRE into `gtnh/java` |
| gtnh-daily-updater Download | every update | Installs or refreshes the updater in `gtnh/updater` from GitHub Releases |
| GTNH Server Pack Install | first update only (no `lwjgl3ify-forgePatches.jar` yet) | Downloads and unpacks a daily build from [GTNH-Daily-Builds](https://github.com/GTNewHorizons/GTNH-Daily-Builds/releases) (or the pack chosen by *Initial Config Version* / *Base Server Pack URL*) |
| GTNH Pack Update | every update | `init` once, then `gtnh-daily-updater update` |

AMP stops the server before updating and the updater only runs then, so mods and configs are
never replaced under a running server.

#### Fresh install

1. Create the instance, tick **Accept Minecraft EULA**, set memory (6 GB + 0.5–1 GB per extra player).
2. Press **Update**. With **Initial Config Version** and **Base Server Pack URL** empty (default)
   the latest daily server pack from GTNH-Daily-Builds is installed; its config version is read
   from the build manifest. To start from a specific daily, set **Daily Build Tag**
   (e.g. `daily-2026-10-27+803`) before the first update.
   To start from a stable release instead, set **Initial Config Version** to it (e.g. `2.8.4`).
3. Start the server. Add players with `whitelist add <name>` (whitelist is on by default).

#### Moving an existing server into AMP

1. Upload the server files into `gtnh/server/` (the folder with `mods/`, `config/`, `lwjgl3ify-forgePatches.jar`).
2. Set **Initial Config Version** to the server's **exact** current config version
   (e.g. `2.9.0-nightly-2026-10-27`, found in the build's `gtnh-*-manifest.json`).
   A wrong value makes the config merge treat pack changes as your edits and vice versa.
3. Press **Update**.

#### Notes

- **git is required** for the config merge. In Docker it is installed via `ExtraContainerPackages`;
  on a bare Linux host install `git`, `unzip`, `wget` and `jq`; on Windows install Git for Windows.
- **Pack Mode**, **Daily Build Tag**, **Initial Config Version** and **Base Server Pack URL** are used
  only on the first update. To re-initialize, delete `gtnh/server/.gtnh-daily-updater.json`.
- The config version of the installed pack is saved to `gtnh/initial-config.txt` and used when
  **Initial Config Version** is empty.
- See your config edits relative to the pack: run
  `gtnh/updater/gtnh-daily-updater config diff --instance-dir gtnh/server` on the host.
- The updater stamps the pack version into the MOTD while it starts with `GT:New Horizons`;
  set a custom MOTD through **Additional Server Settings** (`motd=...`) to opt out.
- `java9args.txt` and the start command come from the server pack. If a future lwjgl3ify release
  changes the required JVM arguments, copy the new `java9args.txt` from a fresh server pack.
- Before the first update of a world you care about, take an AMP backup.

## Editing templates

`*updates.json` files with script stages are generated — do not edit them by hand.
Edit the readable scripts in `tools/<template>/` and rebuild:

```bash
python tools/build.py
```

Scripts are joined into a single command line, so every statement must end with `;`
(or a block keyword such as `then` / `{`) and comments must be on their own line.
In PowerShell scripts keep AMP path placeholders in single quotes.
