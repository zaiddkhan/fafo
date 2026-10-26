#!/usr/bin/env bash
# Installs the five V3 sounds (brief 7.4). Usage, from frontend/:
#   tool/install_sounds.sh /path/to/folder   # containing n, ns, yn, fr, exp .mp3
set -euo pipefail

src="${1:?Pass the folder that holds n.mp3 ns.mp3 yn.mp3 fr.mp3 exp.mp3}"
names=(n ns yn fr exp)

for name in "${names[@]}"; do
  [[ -f "$src/$name.mp3" ]] || { echo "Missing $src/$name.mp3" >&2; exit 1; }
done

# In-app playback (all five).
for name in "${names[@]}"; do
  cp "$src/$name.mp3" "assets/sounds/$name.mp3"
done

# Android notification channel sounds (N and EXP). Android plays mp3 from raw.
cp "$src/n.mp3" android/app/src/main/res/raw/n.mp3
cp "$src/exp.mp3" android/app/src/main/res/raw/exp.mp3

# iOS push sounds must be bundled as .caf/.aiff/.wav and under 30 seconds.
mkdir -p ios/Runner/Sounds
for name in n exp; do
  afconvert -f caff -d LEI16@44100 "$src/$name.mp3" "ios/Runner/Sounds/$name.caf"
  secs=$(afinfo "ios/Runner/Sounds/$name.caf" | awk '/estimated duration/ {print int($3)}')
  if [[ "${secs:-0}" -ge 30 ]]; then
    echo "Warning: $name is ${secs}s; iOS push sounds must be under 30s." >&2
  fi
done

echo "Done. Next:"
echo "  1. Add ios/Runner/Sounds/n.caf and exp.caf to the Runner target in Xcode."
echo "  2. Set FeatureFlags.customSounds = true."
echo "  3. Set NUDGE_CUSTOM_SOUNDS=1 on the backend."
