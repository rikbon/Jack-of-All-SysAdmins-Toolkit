# Build and Packaging

The repository provides one build entry point per shell environment. Both read the version from `VERSION` and produce separate platform archives.

## Bash

```bash
./build.sh
```

Optional arguments:

```bash
./build.sh -v 2.1.0 -o ./dist
```

## PowerShell

```powershell
.\build.ps1
```

Optional arguments:

```powershell
.\build.ps1 -Version 2.1.0 -OutputDirectory .\dist
```

## Output

For each existing platform directory, the build creates:

- `SysAdminToolbox_Windows_vVERSION.zip`
- `SysAdminToolbox_Linux_vVERSION.zip`
- `SysAdminToolbox_macOS_vVERSION.zip`

plus the canonical asset names the installers download by name:

- `Jack-of-All-SysAdmins-Toolkit-windows.zip`
- `Jack-of-All-SysAdmins-Toolkit-linux.tar.gz`

Each archive contains the platform directory, shared project metadata, `VERSION`, and the canonical `docs/` directory.

> The Linux `.tar.gz` is produced by both `build.sh` and `Windows/build.ps1`. If it is missing, `install.sh` falls back to downloading the GitHub source archive, which unpacks the entire repository into the install directory.

## Validation

Run the static validation suite before packaging:

```bash
./validate.sh
```

It checks shell syntax and CRLF line endings for every shell script (platform
directories, root scripts, and tests), the `VERSION` format, the behavioural
tests, `shellcheck`, PowerShell parsing (when `pwsh` is available), and the
generated archive layout.

## Continuous integration

`.github/workflows/ci.yml` runs the same suite on Ubuntu, macOS, and Windows on
every push and pull request, including a dedicated job that fails if any shell
script is checked out with CRLF endings.
