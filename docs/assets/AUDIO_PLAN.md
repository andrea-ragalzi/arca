# ARCA sprint audio

Store cues as `arca/audio/<category>/<cue>_<nn>.wav`. Use mono, 48 kHz, signed 16-bit PCM for all cues. Maximum peak is −1 dBFS. The breath, ambience and alarm have forward loops. All other files are one-shots. Use gain in the game to balance the mix.

| Category | Cue files | Loop |
| --- | --- | --- |
| raptor | roar_01, roar_02, bite_01, hurt_01, hurt_02, death_01, footstep_01–03 | No |
| raptor | breath_01 | Yes |
| env | ambience_01, alarm_01 | Yes |
| door | servo_open_01, locked_deny_01 | No |
| ui | keycard_accept_01, note_open_01 | No |

Approved source recordings are CC0.

- Raptor vocalizations and breathing. [Velociraptor_Growls.aif by crcavol](https://freesound.org/people/crcavol/sounds/154637/)
- Bite. [Bite 1.wav by HenKonen](https://freesound.org/people/HenKonen/sounds/682094/)
- Footsteps. [Footsteps Concrete by LewisEmmott5](https://freesound.org/people/LewisEmmott5/sounds/732571/)
- Room ambience. [Industrial Machine Drone by kkenny101](https://freesound.org/people/kkenny101/sounds/854269/)
- Alarm, servo, denied, keycard and note cues are ARCA original synthesised audio under MIT.

Freesound requires login for original-file downloads. The reproducible source inputs are the four approved recordings' public HQ previews. See `AUDIO_MANIFEST.md` and `ATTRIBUTIONS.md` for exact input URLs and SHA-256 hashes.
