# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "google-api-python-client>=2.100",
#   "google-auth>=2.20",
# ]
# ///
"""Publish MeshTrax to Google Play through the Play Developer API.

Called by release.sh --play; also usable on its own:

  uv run tool/play_upload.py check --version-code 49
  uv run tool/play_upload.py upload --aab dist/meshtrax-v1.7.39.aab \
      --notes-file dist/whatsnew-v1.7.39.txt [--track internal] [--rollout 0.2]

Authenticates with a service-account JSON key kept outside the repo. Setup:
docs/store/google-play-notes.md.
"""

import argparse
import os
import sys
from pathlib import Path

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload

PACKAGE = "com.vena.meshtrax"
DEFAULT_KEY = Path.home() / "Desktop" / "keyStore" / "meshtrax-play-service-account.json"
NOTES_LIMIT = 500


def key_path() -> Path:
    return Path(os.environ.get("PLAY_SERVICE_ACCOUNT_JSON", DEFAULT_KEY))


def service():
    key = key_path()
    if not key.is_file():
        sys.exit(
            f"error: Play service-account key not found at {key}\n"
            "       See docs/store/google-play-notes.md (one-time setup)."
        )
    creds = service_account.Credentials.from_service_account_file(
        str(key), scopes=["https://www.googleapis.com/auth/androidpublisher"]
    )
    return build("androidpublisher", "v3", credentials=creds, cache_discovery=False)


def highest_version_code(edits, edit_id: str) -> int:
    tracks = edits.tracks().list(packageName=PACKAGE, editId=edit_id).execute()
    codes = [
        int(code)
        for track in tracks.get("tracks", [])
        for release in track.get("releases", [])
        for code in release.get("versionCodes", [])
    ]
    return max(codes, default=0)


def check(args) -> None:
    edits = service().edits()
    edit_id = edits.insert(packageName=PACKAGE, body={}).execute()["id"]
    try:
        highest = highest_version_code(edits, edit_id)
    finally:
        edits.delete(packageName=PACKAGE, editId=edit_id).execute()
    if args.version_code <= highest:
        sys.exit(
            f"error: versionCode {args.version_code} is not above the highest on Play "
            f"({highest}).\n       Bump the +build number in pubspec.yaml."
        )
    print(f"PLAY: access OK; versionCode {args.version_code} > {highest} on Play.")


def read_notes(path: Path) -> str:
    lines = path.read_text(encoding="utf-8-sig").splitlines()
    notes = "\n".join(l for l in lines if not l.lstrip().startswith("#")).strip()
    if not notes:
        sys.exit(f"error: {path} has no release notes.")
    if len(notes) > NOTES_LIMIT:
        sys.exit(f"error: release notes are {len(notes)} chars; Play allows {NOTES_LIMIT}.")
    return notes


def upload(args) -> None:
    notes = read_notes(args.notes_file)
    edits = service().edits()
    edit_id = edits.insert(packageName=PACKAGE, body={}).execute()["id"]

    print(f"PLAY: uploading {args.aab} ...")
    media = MediaFileUpload(str(args.aab), mimetype="application/octet-stream", resumable=True)
    bundle = edits.bundles().upload(packageName=PACKAGE, editId=edit_id, media_body=media).execute()
    version_code = bundle["versionCode"]

    release = {
        "versionCodes": [str(version_code)],
        "status": "completed" if args.rollout >= 1 else "inProgress",
        "releaseNotes": [{"language": "en-US", "text": notes}],
    }
    if args.rollout < 1:
        release["userFraction"] = args.rollout
    edits.tracks().update(
        packageName=PACKAGE,
        editId=edit_id,
        track=args.track,
        body={"track": args.track, "releases": [release]},
    ).execute()

    edits.commit(packageName=PACKAGE, editId=edit_id).execute()
    rollout = "full rollout" if args.rollout >= 1 else f"{args.rollout:.0%} staged rollout"
    print(f"PLAY: versionCode {version_code} committed to '{args.track}' ({rollout}).")
    print("      Google reviews it before it reaches users; watch Play Console > Publishing overview.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="command", required=True)

    p_check = sub.add_parser("check", help="verify access and that the versionCode is new")
    p_check.add_argument("--version-code", type=int, required=True)
    p_check.set_defaults(func=check)

    p_upload = sub.add_parser("upload", help="upload an AAB and release it on a track")
    p_upload.add_argument("--aab", type=Path, required=True)
    p_upload.add_argument("--notes-file", type=Path, required=True)
    p_upload.add_argument("--track", default="production")
    p_upload.add_argument("--rollout", type=float, default=1.0)
    p_upload.set_defaults(func=upload)

    args = parser.parse_args()
    if args.command == "upload":
        if not args.aab.is_file():
            sys.exit(f"error: AAB not found: {args.aab}")
        if not 0 < args.rollout <= 1:
            sys.exit("error: --rollout must be in (0, 1].")
    try:
        args.func(args)
    except HttpError as e:
        sys.exit(f"error: Play API {e.status_code}: {e.reason}")


if __name__ == "__main__":
    main()
