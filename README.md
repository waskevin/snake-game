# snake-game

This workspace builds a TOS 7 external-open Snake app as a dual deb package.

Outputs:

- `snake-game-app_1.0.001_all.deb`: metadata package
- `snake-game-service_1.0.001_<arch>.deb`: runnable service package
- `snake-game_<platform>.tar.gz`: final delivery archive
- `snake-game_<platform>.tar.gz.sha256`: checksum for the final archive

Build:

```powershell
wsl bash ./scripts/build.sh amd64
wsl bash ./scripts/build.sh arm64
```

Validate:

```powershell
wsl bash ./scripts/validate.sh amd64
wsl bash ./scripts/validate.sh arm64
```

Artifacts are written to `dist/<arch>/`.
