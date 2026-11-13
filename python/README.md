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

The Python app and its packages are staged before the Flutter build, and the same environment
variables must be set for both steps, so use the wrapper:

```bash
tool/flutter_python.sh android run            # or: ios | macos | windows | linux
tool/flutter_python.sh ios build ipa
tool/flutter_python.sh android build appbundle
```

It runs `dart run serious_python:main package python/app -p <Platform> …` into
`build/python/<platform>/` and then `flutter <args>` with `SERIOUS_PYTHON_*` exported.
A plain `flutter run` without the wrapper builds an app without Python: enhancing then fails
with "the audio engine did not start". Web has no embedded Python; the feature reports that it
is unavailable there.
