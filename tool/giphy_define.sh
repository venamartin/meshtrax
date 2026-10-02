# Sourced by release.sh, buildapk.sh and buildaab.sh. Sets GIPHY_DEFINE as a
# bash array: one --dart-define argument when giphy.key at the repo root holds
# the project's own Giphy API key, empty otherwise (the app then falls back to
# the public beta key; see lib/widgets/gif_picker.dart).
#
# Giphy keys are alphanumeric, so strip every other byte rather than trusting
# the file's encoding: this survives a BOM, UTF-16 padding from a PowerShell
# redirect, CRLF and stray whitespace. An empty result must NOT produce an
# empty define — String.fromEnvironment only falls back when the define is
# absent, so an empty one would ship a broken key.
GIPHY_DEFINE=()
if [ -f giphy.key ]; then
  GIPHY_KEY="$(tr -cd '[:alnum:]' < giphy.key)"
  if [ -n "$GIPHY_KEY" ]; then
    GIPHY_DEFINE=(--dart-define=GIPHY_API_KEY="$GIPHY_KEY")
    echo "==> Using Giphy API key from giphy.key"
  else
    echo "warning: giphy.key contains no usable key; using public beta key" >&2
  fi
fi
