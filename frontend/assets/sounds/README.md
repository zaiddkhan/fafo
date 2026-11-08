# FaFo sounds (V3 brief 7.4)

Six MP3s, named exactly:

| File      | Sound              | When                                             | Plays via            |
|-----------|--------------------|--------------------------------------------------|----------------------|
| `n.mp3`   | Notification (N)   | Receiver, when a nudge arrives                   | Push (channel / APNs) |
| `ns.mp3`  | Nudge sent (NS)    | Sender, when the nudge goes out                  | In app               |
| `yes.mp3` | Yes tap (YN)       | On tapping Yes                                   | In app               |
| `no.mp3`  | No tap (YN)        | On tapping No                                    | In app               |
| `fr.mp3`  | I'm free (FR)      | On switching "I'm free rn" on                    | In app               |
| `exp.mp3` | Timer going off    | A timer hits zero (expiry, go time)              | Push + in app        |

**Installed (8 Nov 2026):** `ns`, `yes`, `no`, `fr`, from the client's
"Sounds" folder. Leading/trailing silence was trimmed so they play on the tap.
The client's single "Yes and No" file held two sounds: the first is `yes`, the
second `no`. `FeatureFlags.inAppSounds` is on.

**Still missing:** `n.mp3` and `exp.mp3` (the push sounds). Until they land,
pushes use the system sound and the in-app timer sound is skipped. When they
arrive, trim any silence and run `tool/install_sounds.sh <folder>` from
`frontend/` (the folder must hold all six). It copies them here, into Android
`res/raw`, and converts N and EXP to `.caf` for iOS push sounds. Then flip
`FeatureFlags.customSounds` to `true`, set `NUDGE_CUSTOM_SOUNDS=1` on the
backend, and add `ios/Runner/Sounds/*.caf` to the Runner target in Xcode (Copy
Bundle Resources).
