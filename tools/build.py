"""Zips the shader pack into dist/, ready for a shaderpacks folder: `oh shiny <version>.zip`.

Iris and Leadlight show the zip's name in their pack lists, so that is the name the pack goes by.

    python3 tools/build.py
"""

import zipfile
from pathlib import Path

PACK = Path(__file__).resolve().parent.parent
VERSION = (PACK / "VERSION").read_text().strip()


def main():
    output = PACK / "dist" / f"oh shiny {VERSION}.zip"
    output.parent.mkdir(exist_ok=True)
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in sorted((PACK / "shaders").rglob("*")):
            if path.is_file() and path.name != ".DS_Store":
                archive.write(path, path.relative_to(PACK).as_posix())
        archive.write(PACK / "LICENSE", "LICENSE")
        archive.write(PACK / "branding" / "icon.png", "pack.png")
    print(output.relative_to(PACK))


if __name__ == "__main__":
    main()
