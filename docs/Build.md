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

Each archive contains the platform directory, shared project metadata, `VERSION`, and the canonical `docs/` directory.

## Validation

Run the static validation suite before packaging:

```bash
./validate.sh
```
