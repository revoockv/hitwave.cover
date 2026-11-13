# Embedded Python

The app processes recorded vocals with Python running on the device (serious_python):
`app/main.py` connects `app/vocal_enhance/` to the Dart side over `dart_bridge`.

- `app/vocal_enhance/` is **generated**: a copy of the `revoockv-vocal-enhance` skill's engine
  without its CLI. Change the engine in the skill, test it there, then copy it here:

  ```bash
  ~/.agents/skills/revoockv-vocal-enhance/scripts/sync_to_app.sh .
  ```

  `app/vocal_enhance/SYNCED.txt` shows the version and checksum of the copy.
- `requirements.txt` pins numpy and scipy to versions that have iOS and Android wheels on
  <https://pypi.flet.dev> for the bundled CPython (3.14). Check that index before changing them.

## Build and run

The Python app and its packages are packaged by `tool/package_python.sh <platform>` into
`build/python/<platform>/` (on iOS/macOS also into the `serious_python_darwin` Swift package).
It skips the work when nothing under `python/` changed since the last run, so the builds call it
every time:

- **Android:** `android/settings.gradle.kts` runs it and sets the `SERIOUS_PYTHON_*` variables the
  plugin's Gradle script reads;
- **iOS / macOS:** a pre-action of the `Runner` scheme runs it (log: `build/python/package_<platform>.log`).

So a plain `flutter run` (or the IDE) ships Python. `tool/flutter_python.sh` still works and is
the way for Windows and Linux:

```bash
tool/flutter_python.sh android run            # or: ios | macos | windows | linux
tool/package_python.sh macos --force          # repackage even when nothing changed
```

Web has no embedded Python; the feature reports that it
is unavailable there.
