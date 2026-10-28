"""Builds <template>updates.json from the readable stage scripts in tools/<template>/.

AMP runs each "Executable" stage as `<UpdateSourceData> <UpdateSourceArgs>`, where the
args are a single command-line string. Editing the escaped one-liners by hand is
error-prone, so the scripts live as normal files and are packed here.

Script rules (so lines can be joined into one line):
  - lines starting with '#' are dropped, so no trailing comments after code;
  - every statement ends with ';' or a block keyword (then/do/else/{).

Usage: python tools/build.py
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
INSTANCE_JAVA = "{{Windows:java\\bin\\java.exe}}{{Linux:java/bin/java}}"


def load_script(template: str, name: str) -> str:
    lines = (ROOT / "tools" / template / name).read_text(encoding="utf-8").splitlines()
    kept = [ln.strip() for ln in lines if ln.strip() and not ln.strip().startswith("#")]
    return " ".join(kept)


def quote_arg(arg: str) -> str:
    """Quotes one argument using the Windows/.NET command-line rules AMP relies on:
    backslashes are literal unless they precede a double quote."""
    out, backslashes = [], 0
    for ch in arg:
        if ch == "\\":
            backslashes += 1
            continue
        if ch == '"':
            out.append("\\" * (backslashes * 2 + 1) + '"')
        else:
            out.append("\\" * backslashes + ch)
        backslashes = 0
    out.append("\\" * (backslashes * 2))
    return '"' + "".join(out) + '"'


def bash_stage(name: str, template: str, script: str, **extra) -> dict:
    return {
        "UpdateStageName": name,
        "UpdateSourcePlatform": "Linux",
        "UpdateSource": "Executable",
        "UpdateSourceData": "/bin/bash",
        "UpdateSourceArgs": "-c " + quote_arg(load_script(template, script)),
        **extra,
        "SkipOnFailure": False,
    }


def pwsh_stage(name: str, template: str, script: str, **extra) -> dict:
    return {
        "UpdateStageName": name,
        "UpdateSourcePlatform": "Windows",
        "UpdateSource": "Executable",
        "UpdateSourceData": "powershell.exe",
        "UpdateSourceArgs": "-NoProfile -ExecutionPolicy Bypass -Command " + quote_arg(load_script(template, script)),
        **extra,
        "SkipOnFailure": False,
    }


def both(name: str, template: str, base: str, **extra) -> list:
    return [
        bash_stage(name, template, base + ".sh", **extra),
        pwsh_stage(name, template, base + ".ps1", **extra),
    ]


def gtnh_daily() -> list:
    t = "gtnh-daily"
    java_condition = {
        "UpdateSourceConditionSetting": "JavaVersion",
        "UpdateSourceConditionValue": INSTANCE_JAVA,
    }
    return [
        {
            "UpdateStageName": "Server Directory Creation",
            "UpdateSourcePlatform": "All",
            "UpdateSource": "CreateDirectory",
            "UpdateSourceArgs": "{{$FullBaseDir}}",
            "SkipOnFailure": False,
        },
        *both("Java Download", t, "java-download", **java_condition),
        *both("gtnh-daily-updater Download", t, "updater-download"),
        *both("GTNH Server Pack Install", t, "server-install"),
        *both("GTNH Pack Update", t, "pack-update"),
    ]


TEMPLATES = {"gtnh-daily": gtnh_daily}


def main() -> None:
    for name, build in TEMPLATES.items():
        path = ROOT / f"{name}updates.json"
        path.write_text(json.dumps(build(), indent=4, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
        print(f"wrote {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
