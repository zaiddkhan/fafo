# FaFo sounds (V3 brief 7.4)

Drop the five files here as MP3, named exactly:

| File      | Sound              | When                                             | Plays via            |
|-----------|--------------------|--------------------------------------------------|----------------------|
| `n.mp3`   | Notification (N)   | Receiver, when a nudge arrives                   | Push (channel / APNs) |
| `ns.mp3`  | Nudge sent (NS)    | Sender, when the nudge goes out                  | In app               |
| `yn.mp3`  | Yes / No tap (YN)  | On tapping either answer                         | In app               |
| `fr.mp3`  | I'm free (FR)      | On switching "I'm free rn" on                    | In app               |
| `exp.mp3` | Timer going off    | A timer hits zero (expiry, go time)              | Push + in app        |

Then run `tool/install_sounds.sh <folder-with-the-five-mp3s>` from `frontend/`.
It copies them here, into Android `res/raw`, and converts N and EXP to `.caf`
for iOS push sounds. Finally flip `FeatureFlags.customSounds` to `true`, set
`NUDGE_CUSTOM_SOUNDS=1` on the backend, and add `ios/Runner/Sounds/*.caf` to
the Runner target in Xcode (Copy Bundle Resources).

Until then every sound falls back to the system default and in-app sounds are
silent, so nothing breaks while files are missing.
