# Next.js Preparation Script

> Automates initial setup for a Next.js project
> **⚠️ Warning:** This script modify and delete files in your project. Run it at your own risk. Always use a clean Git state or backup. Author is not responsible for any data loss.

- [When to Run](#WhentoRun)
- [What it Does](#WhatItDoes)
- [Usage](#Usage)
- [License](#License)

## When to Run

It is highly recommended to run this script **immediately after the first commit (`init`)** of your newly created Next.js project.

## What It Does

This script automates initial project setup for a Next.js + TypeScript project, including:

- Installs recommended development packages (ESLint, Prettier, Husky, TailwindCSS plugins, etc.)
- Configures **Prettier** and **ESLint** with sensible defaults
- Sets up **Husky** pre-commit hooks
- Cleans up project structure (`src/app` and `public`) and generates boilerplate files
- Updates `.gitignore` and creates `.env.example`
- Runs **ESLint auto-fix** on source files
- Optionally commits changes to Git

After running, the script deletes itself automatically.

## Usage

### Linux / macOS

```bash
wget https://scripts.ksprptr.dev/nextjs/bash

chmod +x prepare.sh

./prepare.sh
```

### Windows (PowerShell)

```bash
Invoke-WebRequest https://scripts.ksprptr.dev/nextjs/ps -OutFile prepare.ps1

./prepare.ps1
```

## License

> This script is developed by Petr Kašpar and is licensed under the MIT License.
> For more details, please refer to the LICENSE file.
