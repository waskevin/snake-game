# snake-game

This workspace builds a TOS 7 external-open Snake app as a dual deb package.

Outputs:

- `snake-game-app_<version>_<arch>.deb`: metadata package
- `snake-game-service_<version>_<arch>.deb`: runnable service package
- `snake-game_<platform>.tar.gz`: final delivery archive
- `SHA256SUMS.txt`: checksums for the generated artifacts

Build:

```powershell
wsl bash /mnt/c/Users/guan/Documents/'deb包测试'/scripts/build.sh amd64
wsl bash /mnt/c/Users/guan/Documents/'deb包测试'/scripts/build.sh arm64
```

Validate:

```powershell
wsl bash /mnt/c/Users/guan/Documents/'deb包测试'/scripts/validate.sh amd64
wsl bash /mnt/c/Users/guan/Documents/'deb包测试'/scripts/validate.sh arm64
```

Artifacts are written to `dist/<arch>/`.
