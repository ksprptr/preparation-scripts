# NestJS Preparation Script

> Automates the initial setup of a NestJS project by generating structure, configuration, and common utilities.

> **⚠️ Warning**  
> This script _modifies and removes files_ in your project.  
> Use it only on a clean Git state or after backing up your project.  
> The author is **not responsible** for any data loss.

- [When to Run](#when-to-run)
- [Usage](#usage)

## When to Run

Run this script **right after creating a new NestJS project** and making your initial `init` commit.  
This ensures the script can safely restructure your project without conflicts.

## Usage

### Linux / macOS

> Dependencies: `wget`, `bash`

```bash
wget https://scripts.ksprptr.dev/nestjs/prepare.sh && chmod +x prepare.sh && ./prepare.sh
```

### Windows (PowerShell)

> Dependencies: `winget`, `Git for Windows` (for `bash` shell)

```bash
Invoke-WebRequest -Uri "https://scripts.ksprptr.dev/nestjs/prepare.sh" -OutFile "prepare.sh"

winget install --id Git.Git -e

& "C:\Program Files\Git\bin\bash.exe" -lc "chmod +x ./prepare.sh && ./prepare.sh"

# Optional cleanup
winget uninstall --id Git.Git
```
