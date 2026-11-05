"""Uploads dist/oh shiny! <version>.zip to Modrinth or CurseForge, and keeps the Modrinth listing in sync with MODRINTH.md.

The Modrinth version copies its loaders and game versions from the latest one there. CurseForge uploads go to review, and
its project description can only be changed on the site. Add the new IDs to MODRINTH.md afterwards.

    python3 tools/build.py
    MODRINTH_API_KEY=... python3 tools/publish.py modrinth [--dry-run]
    CURSEFORGE_API_KEY=... python3 tools/publish.py curseforge [--dry-run]
"""

import json
import os
import re
import sys
import urllib.error
import urllib.request
import uuid
from pathlib import Path

PACK = Path(__file__).resolve().parent.parent
VERSION = (PACK / "VERSION").read_text().strip()
ZIP = PACK / "dist" / f"oh shiny! {VERSION}.zip"
USER_AGENT = "simply-sunny/oh-shiny (github.com/simply-sunny/oh-shiny)"
MODRINTH = "https://api.modrinth.com/v2"
CURSEFORGE = "https://minecraft.curseforge.com/api"
MODRINTH_PROJECT = "1YIPfAv7"
CURSEFORGE_PROJECT = "1769227"
GAME_VERSIONS = ["1.20.1", "1.20.2", "1.20.3", "1.20.4", "1.20.5", "1.20.6", "1.21", "1.21.1", "1.21.2", "1.21.3",
                 "1.21.4", "1.21.5", "1.21.6", "1.21.7", "1.21.8", "1.21.9", "1.21.10", "1.21.11", "26.1", "26.1.1",
                 "26.1.2", "26.2", "26.3"]


def call(url, headers, data=None, method=None, content_type=None):
    request = urllib.request.Request(url, data=data, method=method, headers={"User-Agent": USER_AGENT, **headers})
    if content_type:
        request.add_header("Content-Type", content_type)
    try:
        with urllib.request.urlopen(request) as response:
            body = response.read()
            return json.loads(body) if body else None
    except urllib.error.HTTPError as error:
        sys.exit(f"{method or 'GET'} {url} -> {error.code}: {error.read().decode()[:800]}")


def notes():
    text = (PACK / "CHANGELOG.md").read_text()
    return re.search(rf"^## \[{re.escape(VERSION)}\][^\n]*\n(.*?)(?=^## |\Z)", text, re.S | re.M).group(1).strip()


def file_part(mime):
    return (f'Content-Disposition: form-data; name="file"; filename="{ZIP.name}"\r\n'
            f"Content-Type: {mime}\r\n\r\n").encode() + ZIP.read_bytes()


def modrinth(dry_run):
    headers = {"Authorization": os.environ["MODRINTH_API_KEY"]}
    head, body = (PACK / "MODRINTH.md").read_text().split("\n---\n", 1)
    summary = dict(re.findall(r"^\| ([^|]+?) \| (.+?) \|$", head, re.M))["Summary"]
    versions = call(f"{MODRINTH}/project/{MODRINTH_PROJECT}/version", headers)
    if any(version["version_number"] == VERSION for version in versions):
        sys.exit(f"{VERSION} is already on Modrinth")
    latest = versions[0]
    data = {
        "project_id": MODRINTH_PROJECT,
        "name": f"oh shiny! {VERSION}",
        "version_number": VERSION,
        "changelog": notes(),
        "dependencies": latest["dependencies"],
        "game_versions": latest["game_versions"],
        "version_type": "release",
        "loaders": latest["loaders"],
        "featured": latest["featured"],
        "status": "listed",
        "file_parts": ["file"],
        "primary_file": "file",
    }
    if dry_run:
        print(json.dumps({**data, "changelog": f"<{len(data['changelog'])} chars>"}), ZIP.name)
        return
    call(f"{MODRINTH}/project/{MODRINTH_PROJECT}", headers, json.dumps({"description": summary, "body": body.strip()}).encode(),
         "PATCH", "application/json")
    boundary = uuid.uuid4().hex
    payload = (f'--{boundary}\r\nContent-Disposition: form-data; name="data"\r\nContent-Type: application/json\r\n\r\n'
               f"{json.dumps(data)}\r\n--{boundary}\r\n").encode() + file_part("application/zip") + f"\r\n--{boundary}--\r\n".encode()
    version = call(f"{MODRINTH}/version", headers, payload, "POST", f"multipart/form-data; boundary={boundary}")
    print("Modrinth version", version["id"])


def curseforge(dry_run):
    headers = {"X-Api-Token": os.environ["CURSEFORGE_API_KEY"]}
    types = {kind["id"]: kind["slug"] for kind in call(f"{CURSEFORGE}/game/version-types", headers)}
    ids = {}
    for version in call(f"{CURSEFORGE}/game/versions", headers):
        if types.get(version["gameVersionTypeID"], "").startswith("minecraft-"):
            ids.setdefault(version["name"], version["id"])
    missing = [name for name in GAME_VERSIONS if name not in ids]
    if missing:
        sys.exit(f"CurseForge has no version tag for {missing}")
    metadata = {
        "changelog": notes(),
        "changelogType": "markdown",
        "displayName": f"oh shiny! {VERSION}",
        "gameVersions": [ids[name] for name in GAME_VERSIONS],
        "releaseType": "release",
    }
    if dry_run:
        print(json.dumps({**metadata, "changelog": f"<{len(metadata['changelog'])} chars>"}), ZIP.name)
        return
    boundary = uuid.uuid4().hex
    payload = (f'--{boundary}\r\nContent-Disposition: form-data; name="metadata"\r\n\r\n{json.dumps(metadata)}\r\n--{boundary}\r\n').encode() \
        + file_part("application/zip") + f"\r\n--{boundary}--\r\n".encode()
    result = call(f"{CURSEFORGE}/projects/{CURSEFORGE_PROJECT}/upload-file", headers, payload, "POST",
                  f"multipart/form-data; boundary={boundary}")
    print("CurseForge file", result["id"])


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in ("modrinth", "curseforge"):
        sys.exit(__doc__)
    if not ZIP.is_file():
        sys.exit(f"missing {ZIP}, run tools/build.py")
    {"modrinth": modrinth, "curseforge": curseforge}[sys.argv[1]]("--dry-run" in sys.argv)


if __name__ == "__main__":
    main()
