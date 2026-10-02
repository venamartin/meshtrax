# Google Play releases

`./release.sh --play` builds the signed app bundle and publishes it to the
**production** track (full rollout) through the Google Play Developer API.
Google still reviews each release before it reaches users.

Package: `com.vena.meshtrax`. Upload tool: `tool/play_upload.py` (run with `uv`).

## One-time setup

1. **Google Cloud Console** (console.cloud.google.com), signed in as the Play
   developer account owner: create a project (e.g. `meshtrax-release`), then
   APIs & Services → Library → enable **Google Play Android Developer API**.
2. IAM & Admin → **Service accounts** → Create service account
   (`play-publisher`, no project roles) → Keys → Add key → **JSON**.
   Save the file as `~/Desktop/keyStore/meshtrax-play-service-account.json`
   (beside the upload keystore). Never commit it. To keep it elsewhere, set
   `PLAY_SERVICE_ACCOUNT_JSON` to its path.
3. **Play Console → Users and permissions → Invite new users**: enter the
   service account email (`play-publisher@<project>.iam.gserviceaccount.com`),
   then under App permissions add MeshTrax with:
   - Release to production, exclude devices, and use Play App Signing
   - Release apps to testing tracks
   - Manage testing tracks and edit tester lists
   - View app information

   Invite. It usually works within minutes, but can take up to 24 hours.
4. Check it: `uv run tool/play_upload.py check --version-code 1` should fail
   with "not above the highest on Play" — that proves access works.

`android/key.properties` and the upload keystore must also be present
(`buildaab.sh` checks them).

## Releasing

```bash
./release.sh --apk --play        # GitHub APK release + Play
./release.sh --play              # Play only (no GitHub release or tag)
```

1. **Preflight**, before any build: the key works and the pubspec `+build`
   number (the Play versionCode) is higher than anything on Play.
2. **Store notes**: nano opens `dist/whatsnew-v<version>.txt`, prefilled with
   the commit subjects since the last tag as `#` comments. Write the
   "What's new" text (max 500 characters; `#` lines are ignored), save, exit.
   A file left from an aborted run can be reused. `$VISUAL`/`$EDITOR`
   override nano. The same file will feed the Microsoft Store.
3. The app bundle is built and copied to `dist/meshtrax-v<version>.aab`. It
   is never attached to GitHub.
4. Play upload happens **last**, only after the GitHub release goes live. If
   the GitHub draft is rejected, nothing is sent to Play.

If the Play upload fails after GitHub went live, fix the cause and run
`./release.sh --play`. Nothing reaches Play until the final commit succeeds,
so a failed upload leaves no half-finished release.

## Other tracks or staged rollout

Upload by hand with the tool:

```bash
./buildaab.sh
uv run tool/play_upload.py upload --aab build/app/outputs/bundle/release/app-release.aab \
    --notes-file dist/whatsnew-v<version>.txt --track internal      # or alpha, beta
    # --rollout 0.2 for a 20% staged production rollout
```
