# /// script
# requires-python = ">=3.11"
# ///
"""Publish MeshTrax to the Microsoft Store through the Microsoft Store Developer CLI.

Called by release.sh --msstore; also usable on its own:

  uv run tool/msstore_upload.py check --version 1.7.123
  uv run tool/msstore_upload.py upload --msix dist/meshtrax-v1.7.123.msix \
      --notes-file dist/whatsnew-v1.7.123.txt

The msstore CLI holds the Partner Center credentials (msstore reconfigure), so
nothing here reads a key. Setup: docs/store/microsoft-store-notes.md.
"""

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

APP_ID = "9N0DM90LRH49"
NOTES_LIMIT = 1500
REPO_ROOT = Path(__file__).resolve().parent.parent
COMMIT_POLL_SECONDS = 20
COMMIT_POLL_LIMIT = 30
READ_ATTEMPTS = 3
READ_RETRY_SECONDS = 15


def msstore(*args: str, capture: bool = False) -> subprocess.CompletedProcess:
    exe = shutil.which("msstore")
    if exe is None:
        sys.exit(
            "error: the 'msstore' CLI is not on PATH. Install it with:\n"
            '       winget install "Microsoft Store Developer CLI"\n'
            "       See docs/store/microsoft-store-notes.md (one-time setup)."
        )
    return subprocess.run(
        [exe, *args],
        capture_output=capture,
        text=True,
        encoding="utf-8",
        errors="replace",
    )


def read_json(*args: str) -> dict:
    # Reads are retried: the Store API sometimes refuses one call and then
    # answers the next. Progress goes to stderr; stdout carries only the JSON.
    for attempt in range(READ_ATTEMPTS):
        if attempt:
            time.sleep(READ_RETRY_SECONDS)
        result = msstore(*args, capture=True)
        if result.returncode == 0:
            break
    else:
        sys.exit(
            f"error: 'msstore {' '.join(args)}' failed.\n{result.stderr.strip()}\n"
            "       If every call fails, check that the 'Service Principal' row for the\n"
            "       app in Partner Center > User management still has Manager(Windows)."
        )
    out = result.stdout
    return json.loads(out[out.index("{") : out.rindex("}") + 1])


def submission() -> dict:
    """The pending submission when there is one, else the last published."""
    return read_json("submission", "get", APP_ID)


def version_tuple(version: str) -> tuple[int, ...]:
    parts = tuple(int(p) for p in version.split("."))
    return parts + (0,) * (4 - len(parts))


def check(args) -> None:
    app = read_json("apps", "get", APP_ID)
    if app.get("PendingApplicationSubmission"):
        sys.exit(
            "error: MeshTrax already has a submission in progress (a draft or one in\n"
            "       certification). An upload would delete a draft, and cannot replace one\n"
            "       in certification. Finish or delete it in Partner Center first:\n"
            f"       https://partner.microsoft.com/dashboard/products/{APP_ID}/overview"
        )
    live = [
        p["Version"]
        for p in submission().get("ApplicationPackages", [])
        if p.get("FileStatus") != "PendingDelete" and p.get("Version")
    ]
    highest = max(live, key=version_tuple, default="0.0.0.0")
    if version_tuple(args.version) <= version_tuple(highest):
        sys.exit(
            f"error: version {args.version} is not above {highest} in the Store.\n"
            "       Bump the version in pubspec.yaml."
        )
    print(f"MSSTORE: access OK; {args.version} > {highest} in the Store.")


def read_notes(path: Path) -> str:
    lines = path.read_text(encoding="utf-8-sig").splitlines()
    notes = "\n".join(l for l in lines if not l.lstrip().startswith("#")).strip()
    if not notes:
        sys.exit(f"error: {path} has no release notes.")
    if len(notes) > NOTES_LIMIT:
        sys.exit(f"error: release notes are {len(notes)} chars; the Store allows {NOTES_LIMIT}.")
    return notes


def upload(args) -> None:
    notes = read_notes(args.notes_file)

    # The CLI uploads every .msix it finds under --inputDirectory, so it gets a
    # folder holding this one package and nothing else.
    with tempfile.TemporaryDirectory() as staging:
        shutil.copy2(args.msix, staging)
        print(f"MSSTORE: uploading {args.msix.name} to a new draft ...")
        result = msstore(
            "publish", str(REPO_ROOT), "--inputDirectory", staging,
            "--appId", APP_ID, "--noCommit",
        )
    if result.returncode != 0:
        sys.exit("error: package upload failed; nothing was submitted.")

    # 'publish' rebuilt the draft from the last published submission, so the
    # notes go in now, after the upload, never before it.
    draft = submission()
    packages = draft.get("ApplicationPackages", [])
    if draft.get("Status") != "PendingCommit" or not any(
        p.get("FileName") == args.msix.name and p.get("FileStatus") != "PendingDelete"
        for p in packages
    ):
        sys.exit(f"error: the draft does not hold {args.msix.name}; nothing was submitted.")

    for listing in draft.get("Listings", {}).values():
        listing["BaseListing"]["ReleaseNotes"] = notes
    with tempfile.TemporaryDirectory() as tmp:
        payload = Path(tmp) / "submission.json"
        payload.write_text(json.dumps(draft), encoding="utf-8")
        if msstore("submission", "update", APP_ID, "--payload", str(payload)).returncode != 0:
            sys.exit("error: could not set the What's new notes; the draft was not submitted.")

    updated = submission()
    if any(
        l["BaseListing"].get("ReleaseNotes", "").strip() != notes
        for l in updated.get("Listings", {}).values()
    ):
        sys.exit("error: the What's new notes did not stick; the draft was not submitted.")

    if msstore("submission", "publish", APP_ID).returncode != 0:
        sys.exit("error: the draft (package + notes) is in Partner Center but was not submitted.")

    for _ in range(COMMIT_POLL_LIMIT):
        status = submission()
        state = status.get("Status")
        if state == "CommitFailed":
            errors = status.get("StatusDetails", {}).get("Errors") or []
            for e in errors:
                print(f"       {e.get('Code')}: {e.get('Details')}")
            sys.exit("error: the Store rejected the submission while processing it.")
        if state != "CommitStarted":
            break
        time.sleep(COMMIT_POLL_SECONDS)
    else:
        print("MSSTORE: still processing after 10 minutes; check Partner Center.")
        return

    print(f"MSSTORE: {args.msix.name} submitted ({state}).")
    print("         Certification takes hours to 3 business days; the update goes live when it")
    print("         passes. Watch Partner Center > MeshTrax.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="command", required=True)

    p_check = sub.add_parser("check", help="verify access, no pending submission, and a new version")
    p_check.add_argument("--version", required=True)
    p_check.set_defaults(func=check)

    p_upload = sub.add_parser("upload", help="upload an .msix with What's new notes and submit it")
    p_upload.add_argument("--msix", type=Path, required=True)
    p_upload.add_argument("--notes-file", type=Path, required=True)
    p_upload.set_defaults(func=upload)

    args = parser.parse_args()
    if args.command == "upload" and not args.msix.is_file():
        sys.exit(f"error: MSIX not found: {args.msix}")
    args.func(args)


if __name__ == "__main__":
    main()
