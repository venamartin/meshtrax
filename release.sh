#!/bin/bash

# Guard: detect CRLF corruption (Windows line endings break bash parsing)
if file "$0" 2>/dev/null | grep -q "CRLF"; then
    echo "ERROR: release.sh has Windows (CRLF) line endings. Fix with:"
    echo "       sed -i 's/\r//' release.sh   (on Git Bash)"
    echo "  or:  dos2unix release.sh"
    exit 1
fi

# Default flag values
BUILD_APK=false
BUILD_IOS=false
BUILD_WINDOWS=false
BUILD_LINUX=false
APPEND_ONLY=false

# 1. Parse Command Line Arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --apk) BUILD_APK=true ;;
        --ios) BUILD_IOS=true ;;
        --windows) BUILD_WINDOWS=true ;;
        --linux) BUILD_LINUX=true ;;
        --append) APPEND_ONLY=true ;;
        *) echo "ERROR: Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Check if at least one platform was selected
if [ "$BUILD_APK" = false ] && [ "$BUILD_IOS" = false ] && [ "$BUILD_WINDOWS" = false ] && [ "$BUILD_LINUX" = false ]; then
    echo "ERROR: Please specify a platform (e.g., ./release.sh --apk, ./release.sh --windows, ./release.sh --linux)"
    exit 1
fi

# Helper function to zip a directory cross-platform
zip_directory() {
    local source_dir=$1
    local dest_zip=$2
    
    if command -v zip &> /dev/null; then
        local root_dir=$(pwd)
        pushd "$source_dir" > /dev/null
        zip -r "$root_dir/$dest_zip" ./*
        popd > /dev/null
    elif command -v 7z &> /dev/null || command -v 7z.exe &> /dev/null || [ -f "/c/Program Files/7-Zip/7z.exe" ]; then
        local z7_cmd="7z"
        if ! command -v 7z &> /dev/null && ! command -v 7z.exe &> /dev/null; then
            z7_cmd="/c/Program Files/7-Zip/7z.exe"
        fi
        if [ -f "$dest_zip" ]; then
            rm "$dest_zip"
        fi
        local root_dir=$(pwd)
        pushd "$source_dir" > /dev/null
        "$z7_cmd" a -tzip "$root_dir/$dest_zip" *
        popd > /dev/null
    elif command -v powershell.exe &> /dev/null; then
        # Remove old zip if it exists to avoid Compress-Archive appending/erroring
        if [ -f "$dest_zip" ]; then
            rm "$dest_zip"
        fi
        # Using PowerShell to compress the archive
        powershell.exe -Command "Compress-Archive -Path '${source_dir}/*' -DestinationPath '${dest_zip}' -Force"
    else
        echo "ERROR: Neither 'zip', '7z', nor 'powershell.exe' found. Cannot create zip archive."
        return 1
    fi
}

# Guard: a desktop bundle must ship the RELEASE Flutter engine. A debug or
# profile engine cannot load the AOT snapshot, so the app exits immediately
# with no window. This shipped broken for Windows in v1.7.7.
verify_release_engine() {
    local platform=$1
    local bundle_dir=$2

    local engine_rel aot_rel artifact_base
    case "$platform" in
        windows)
            engine_rel="flutter_windows.dll"
            aot_rel="data/app.so"
            artifact_base="windows-x64"
            ;;
        linux)
            engine_rel="lib/libflutter_linux_gtk.so"
            aot_rel="lib/libapp.so"
            artifact_base="linux-x64"
            ;;
        *)
            echo "ERROR: verify_release_engine: unsupported platform '$platform'."
            return 1
            ;;
    esac

    local bundle_engine="$bundle_dir/$engine_rel"
    if [ ! -f "$bundle_engine" ]; then
        echo "ERROR: $bundle_engine is missing. Cannot verify the Flutter engine."
        return 1
    fi
    if [ ! -f "$bundle_dir/$aot_rel" ]; then
        echo "ERROR: $bundle_dir/$aot_rel is missing. This is not an AOT release build."
        return 1
    fi

    local flutter_bin
    flutter_bin=$(command -v flutter)
    if [ -z "$flutter_bin" ]; then
        echo "ERROR: 'flutter' is not on PATH. Cannot verify the Flutter engine."
        return 1
    fi

    local flutter_root engine_cache engine_name
    flutter_root=$(cd "$(dirname "$flutter_bin")/.." && pwd)
    engine_cache="$flutter_root/bin/cache/artifacts/engine"
    engine_name=$(basename "$engine_rel")

    local reference="$engine_cache/$artifact_base-release/$engine_name"
    if [ ! -f "$reference" ]; then
        echo "ERROR: Release engine artifact not found at:"
        echo "       $reference"
        echo "       Run 'flutter precache --$platform' and build again."
        return 1
    fi

    local bundle_sha reference_sha
    bundle_sha=$(sha1sum "$bundle_engine" | cut -d' ' -f1)
    reference_sha=$(sha1sum "$reference" | cut -d' ' -f1)

    if [ "$bundle_sha" = "$reference_sha" ]; then
        echo "VERIFY: $platform release engine confirmed ($bundle_sha)."
        return 0
    fi

    # Name the variant that actually got bundled — debug is the usual culprit.
    local matched="unrecognised (possibly stripped or post-processed)"
    local variant candidate
    for variant in "$artifact_base" "$artifact_base-profile"; do
        candidate="$engine_cache/$variant/$engine_name"
        if [ -f "$candidate" ] && [ "$(sha1sum "$candidate" | cut -d' ' -f1)" = "$bundle_sha" ]; then
            case "$variant" in
                *-profile) matched="the PROFILE engine" ;;
                *)         matched="the DEBUG engine" ;;
            esac
            break
        fi
    done

    echo "ERROR: The $platform bundle does not carry the release Flutter engine."
    echo "       bundled:  $bundle_sha  ($(stat -c%s "$bundle_engine") bytes) - $matched"
    echo "       expected: $reference_sha  ($(stat -c%s "$reference") bytes)"
    echo "       Such an engine cannot load $aot_rel, so the app exits"
    echo "       immediately with no window. Refusing to package it."
    echo "       Fix: flutter clean && flutter build $platform --release"
    return 1
}

# 2. Safety Checks: Uncommitted Changes
if [ -n "$(git status --porcelain | grep -v 'release.sh' | grep -v 'dist/')" ]; then
  echo "ERROR: You have uncommitted changes. Please commit or stash them first."
  git status -s | grep -v 'release.sh' | grep -v 'dist/'
  exit 1
fi

# 2b. Safety Checks: Must be on master branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "master" ]; then
    echo "ERROR: Releases must be built from the 'master' branch."
    echo "       You are currently on '$CURRENT_BRANCH'."
    echo "       Please switch to master and merge your changes before releasing."
    exit 1
fi

# 3. Safety Checks: Verify Remote Sync
UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
if [ -z "$UPSTREAM" ]; then
    echo "ERROR: No upstream branch found. Have you pushed this branch to GitHub yet?"
    exit 1
fi

LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})
if [ "$LOCAL" != "$REMOTE" ]; then
    echo "ERROR: Your local branch is not in sync with GitHub. Push your commits first."
    exit 1
fi

# 4. Extract Version from pubspec.yaml
VERSION=$(grep '^version: ' pubspec.yaml | sed 's/version: //; s/+.*//' | tr -d '\r' | tr -d ' ')

if [ -z "$VERSION" ]; then
    echo "ERROR: Could not find version number in pubspec.yaml"
    exit 1
fi

# 5. Check for Tag Collision
if [ "$APPEND_ONLY" = false ]; then
    if git rev-parse "v$VERSION" >/dev/null 2>&1; then
        echo "ERROR: Tag v$VERSION already exists locally or on GitHub."
        echo "Please increment the version in pubspec.yaml before releasing."
        exit 1
    fi
    echo "SUCCESS: Preparation complete. Ready to build v$VERSION"
else
    echo "SUCCESS: Preparation complete. Appending to existing release v$VERSION"
fi

# 6. Clean and Build Phase
echo "INFO: Running flutter clean..."
flutter clean
flutter pub get

# A registrant left over from an integration-test run breaks the release
# build; see the script for why. Must run AFTER 'flutter pub get' above,
# which is itself capable of regenerating the contaminated file.
bash tool/strip_integration_registrant.sh

DIST_DIR="dist"

if [ "$BUILD_APK" = true ]; then
    echo "BUILD: Starting Android Production Build (arm64-v8a)..."
    flutter build apk --release --split-per-abi
    
    if [ $? -eq 0 ]; then
        mkdir -p "$DIST_DIR"
        
        # arm64-v8a only — covers all modern Android devices (2016+)
        SOURCE_PATH="build/app/outputs/flutter-apk"
        SOURCE_APK="$SOURCE_PATH/app-arm64-v8a-release.apk"
        SOURCE_SHA1="$SOURCE_PATH/app-arm64-v8a-release.apk.sha1"
        
        BASE_NAME="meshtrax-v$VERSION-arm64.apk"
        DEST_APK="$DIST_DIR/$BASE_NAME"
        APK_DEST_SHA1="$DIST_DIR/$BASE_NAME.sha1"
        
        # Move APK and SHA1
        mv "$SOURCE_APK" "$DEST_APK"
        if [ -f "$SOURCE_SHA1" ]; then
            mv "$SOURCE_SHA1" "$APK_DEST_SHA1"
        else
            echo "INFO: Generating new SHA1 checksum..."
            sha1sum "$DEST_APK" | cut -d' ' -f1 > "$APK_DEST_SHA1"
        fi
        
        echo "SUCCESS: Android build complete."
        echo "LOCATION: Artifacts are in '$DIST_DIR/'"
        echo "--------------------------------------------------"
        echo "TESTING: Now is the time to install the APK on your device and test."
        echo "FILE: $DEST_APK"
        echo "--------------------------------------------------"
        
        if [ "$APPEND_ONLY" = false ] && [ "$BUILD_WINDOWS" = false ]; then
            echo "PROMPT: Do you want to proceed to the GitHub Draft phase? (y/n)"
            read -r TEST_CONFIRM
            
            if [ "$TEST_CONFIRM" != "y" ]; then
                echo "INFO: Build preserved in '$DIST_DIR/'. Run this script again when ready to publish."
                exit 0
            fi
        fi
    else
        echo "ERROR: Flutter build failed."
        exit 1
    fi
fi

if [ "$BUILD_WINDOWS" = true ]; then
    echo "BUILD: Starting Windows Production Build..."
    flutter build windows --release
    
    if [ $? -eq 0 ]; then
        mkdir -p "$DIST_DIR"
        
        # Define paths
        SOURCE_PATH="build/windows/x64/runner/Release"
        
        BASE_NAME="meshtrax-windows-v$VERSION.zip"
        WIN_DEST_ZIP="$DIST_DIR/$BASE_NAME"
        WIN_DEST_SHA1="$DIST_DIR/$BASE_NAME.sha1"
        
        verify_release_engine "windows" "$SOURCE_PATH"
        if [ $? -ne 0 ]; then
            echo "ERROR: Aborting. Refusing to ship a broken Windows bundle."
            exit 1
        fi

        # The engine check above only proves the ENGINE is a release build.
        # v1.7.7 also shipped with no flserial.dll and no sqlite3.dll: the app
        # started, listed COM ports, and then told every USB user their
        # platform was unsupported. A missing native library never fails
        # `flutter build`, so it has to be checked before the zip.
        # Use the dart that ships beside the flutter on PATH, so the release
        # never dies on a missing standalone `dart`.
        DART_BIN="$(dirname "$(command -v flutter)")/dart"
        [ -x "$DART_BIN" ] || DART_BIN="dart"
        "$DART_BIN" run tool/verify_windows_bundle.dart --bundle "$SOURCE_PATH"
        if [ $? -ne 0 ]; then
            echo "ERROR: Aborting. Refusing to ship an incomplete Windows bundle."
            exit 1
        fi

        zip_directory "$SOURCE_PATH" "$WIN_DEST_ZIP"
        if [ $? -ne 0 ]; then
            echo "ERROR: Zip file creation failed for Windows."
            exit 1
        fi
        
        if [ -f "$WIN_DEST_ZIP" ]; then
            echo "INFO: Generating SHA1 checksum..."
            sha1sum "$WIN_DEST_ZIP" | cut -d' ' -f1 > "$WIN_DEST_SHA1"
        else
            echo "ERROR: Zip file missing after creation attempt."
            exit 1
        fi
        
        echo "SUCCESS: Windows build complete."
        echo "LOCATION: Artifacts are in '$DIST_DIR/'"
        echo "FILE: $WIN_DEST_ZIP"
        
        if [ "$APPEND_ONLY" = false ] && [ "$BUILD_LINUX" = false ]; then
            echo "PROMPT: Do you want to proceed to the GitHub Draft phase? (y/n)"
            read -r TEST_CONFIRM
            
            if [ "$TEST_CONFIRM" != "y" ]; then
                echo "INFO: Build preserved in '$DIST_DIR/'. Run this script again when ready to publish."
                exit 0
            fi
        fi
    else
        echo "ERROR: Flutter windows build failed."
        exit 1
    fi
fi

if [ "$BUILD_LINUX" = true ]; then
    echo "BUILD: Starting Linux Production Build..."
    flutter build linux --release
    
    if [ $? -eq 0 ]; then
        mkdir -p "$DIST_DIR"
        
        # Define paths
        SOURCE_PATH="build/linux/x64/release/bundle"
        BASE_NAME="meshtrax-linux-v$VERSION.zip"
        LINUX_DEST_ZIP="$DIST_DIR/$BASE_NAME"
        LINUX_DEST_SHA1="$DIST_DIR/$BASE_NAME.sha1"
        
        verify_release_engine "linux" "$SOURCE_PATH"
        if [ $? -ne 0 ]; then
            echo "ERROR: Aborting. Refusing to ship a broken Linux bundle."
            exit 1
        fi

        zip_directory "$SOURCE_PATH" "$LINUX_DEST_ZIP"
        if [ $? -ne 0 ]; then
            echo "ERROR: Zip file creation failed for Linux."
            exit 1
        fi
        
        if [ -f "$LINUX_DEST_ZIP" ]; then
            echo "INFO: Generating SHA1 checksum..."
            sha1sum "$LINUX_DEST_ZIP" | cut -d' ' -f1 > "$LINUX_DEST_SHA1"
        else
            echo "ERROR: Zip file missing after creation attempt."
            exit 1
        fi
        
        echo "SUCCESS: Linux build complete."
        echo "LOCATION: Artifacts are in '$DIST_DIR/'"
        echo "FILE: $LINUX_DEST_ZIP"
        
        if [ "$APPEND_ONLY" = false ]; then
            echo "PROMPT: Do you want to proceed to the GitHub Draft phase? (y/n)"
            read -r TEST_CONFIRM
            
            if [ "$TEST_CONFIRM" != "y" ]; then
                echo "INFO: Build preserved in '$DIST_DIR/'. Run this script again when ready to publish."
                exit 0
            fi
        fi
    else
        echo "ERROR: Flutter linux build failed."
        exit 1
    fi
fi

# 7. Publishing Phase
# Gather files to upload
FILES_TO_UPLOAD=()
if [ "$BUILD_APK" = true ] && [ -f "$DEST_APK" ]; then
    FILES_TO_UPLOAD+=("$DEST_APK")
    if [ -f "$APK_DEST_SHA1" ]; then
        FILES_TO_UPLOAD+=("$APK_DEST_SHA1")
    fi
fi
if [ "$BUILD_WINDOWS" = true ] && [ -f "$WIN_DEST_ZIP" ]; then
    FILES_TO_UPLOAD+=("$WIN_DEST_ZIP")
    if [ -f "$WIN_DEST_SHA1" ]; then
        FILES_TO_UPLOAD+=("$WIN_DEST_SHA1")
    fi
fi
if [ "$BUILD_LINUX" = true ] && [ -f "$LINUX_DEST_ZIP" ]; then
    FILES_TO_UPLOAD+=("$LINUX_DEST_ZIP")
    if [ -f "$LINUX_DEST_SHA1" ]; then
        FILES_TO_UPLOAD+=("$LINUX_DEST_SHA1")
    fi
fi

if [ ${#FILES_TO_UPLOAD[@]} -eq 0 ]; then
    echo "ERROR: No artifacts found to upload."
    exit 1
fi

if [ "$APPEND_ONLY" = true ]; then
    echo "PUBLISH: Appending artifacts to existing release v$VERSION on GitHub..."
    # --clobber replaces assets of the same name. Without it, re-uploading a
    # corrected artifact to an existing release fails outright.
    gh release upload "v$VERSION" "${FILES_TO_UPLOAD[@]}" --clobber
    
    if [ $? -eq 0 ]; then
        echo "SUCCESS: Upload complete!"
    else
        echo "ERROR: Failed to upload artifacts."
        exit 1
    fi
    exit 0
fi

# The Draft Preview
echo "PREVIEW: Creating a DRAFT release on GitHub to preview notes..."

gh release create "v$VERSION" \
    "${FILES_TO_UPLOAD[@]}" \
    --title "Release v$VERSION" \
    --generate-notes \
    --draft

if [ $? -eq 0 ]; then
    echo "SUCCESS: Draft release created."
    echo "ACTION: Opening the draft in your browser for review..."
    gh release view "v$VERSION" --web
    
    echo "--------------------------------------------------"
    echo "PUBLISH: Does the draft and the artifact tests look correct? (y/n)"
    echo "  'y' - Publish officially (Push tag and make release public)"
    echo "  'n' - Abort (Delete draft and clean up)"
    read -r CONFIRM

    if [ "$CONFIRM" = "y" ]; then
        echo "PUBLISH: Pushing official tag v$VERSION to GitHub..."
        git tag -a "v$VERSION" -m "Release v$VERSION"
        git push origin "v$VERSION"
        
        echo "PUBLISH: Making the release public..."
        gh release edit "v$VERSION" --draft=false
        echo "SUCCESS: Release v$VERSION is now LIVE!"
    else
        echo "INFO: Deleting the draft release from GitHub..."
        gh release delete "v$VERSION" --yes
        echo "DONE: Release aborted. Artifacts remain in '$DIST_DIR/'."
    fi
else
    echo "ERROR: Failed to create draft release on GitHub."
    exit 1
fi