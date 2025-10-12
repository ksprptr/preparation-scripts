<#
Next.js Preparation Script
Description: Automates initial setup for a Next.js project
Warning: This script modify and delete files in your project. Run it at your own risk. Always use a clean Git state or backup. Author is not responsible for any data loss.
Author: Petr Kašpar
License: MIT
#>

function Run-Step {
    param (
        [string]$Message,
        [scriptblock]$Action
    )

    Write-Host "`n▶ $Message..."
    try {
        & $Action | Out-Null
        Write-Host "✅ $Message - Done!"
    } catch {
        Write-Host "❌ $Message - FAILED: $($_.Exception.Message)"
        exit 1
    }
}

# --- PRECHECKS ---

if (-not (Test-Path "node_modules/next")) {
    Write-Host "❌ Not a Next.js project. Please create one first."
    exit 1
}

# Detect package manager
if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    $PACKAGE_MANAGER = "pnpm"
} elseif (Get-Command yarn -ErrorAction SilentlyContinue) {
    $PACKAGE_MANAGER = "yarn"
} else {
    $PACKAGE_MANAGER = "npm"
}
Write-Host "Detected package manager: $PACKAGE_MANAGER"

# Check Git repository
if (-not (Test-Path ".git")) {
    Write-Host "Git repository not initialized. Skipping git checks."
    $GIT_COMMIT = "no"
} else {
    $changes = git status --porcelain | Select-String -NotMatch "prepare.ps1"
    if ($changes) {
        Write-Host "❌ You have uncommitted changes. Please commit or stash them first. (ignore prepare.ps1)"
        exit 1
    } else {
        $choice = Read-Host "Git repository detected. Commit changes after preparation? (Y/n)"
        if ($choice -match "^[Nn]") {
            $GIT_COMMIT = "no"
        } else {
            $GIT_COMMIT = "yes"
        }
    }
}

Clear-Host

# --- STEP 1: Install dependencies ---

Run-Step "Installing development packages" {
    $devPackages = @(
        "@eslint/eslintrc", "@eslint/js", "@next/eslint-plugin-next",
        "@typescript-eslint/eslint-plugin", "@typescript-eslint/parser",
        "eslint", "eslint-config-next", "eslint-config-prettier",
        "eslint-plugin-import", "eslint-plugin-prettier", "eslint-plugin-react",
        "eslint-plugin-react-hooks", "eslint-plugin-simple-import-sort",
        "eslint-plugin-unused-imports", "husky", "prettier",
        "prettier-plugin-tailwindcss"
    )

    if ($PACKAGE_MANAGER -eq "pnpm") {
        pnpm add -D $devPackages
        pnpm up --latest
    } elseif ($PACKAGE_MANAGER -eq "yarn") {
        yarn add -D $devPackages
        yarn upgrade --latest
    } else {
        npm install -D $devPackages
        npx npm-check-updates -u
        npm install
    }
}

# --- STEP 2: Prettier config ---

Run-Step "Configuring Prettier" {
@"
{
  "tabWidth": 2,
  "printWidth": 100,
  "endOfLine": "auto",
  "arrowParens": "always",
  "semi": true,
  "singleQuote": true,
  "jsxSingleQuote": true,
  "bracketSameLine": true,
  "plugins": ["prettier-plugin-tailwindcss"]
}
"@ | Set-Content ".prettierrc"

@"
.next
.husky
.prettierignore
.stylelintignore
coverage
node_modules
public
"@ | Set-Content ".prettierignore"
}

# --- STEP 3: ESLint config ---

Run-Step "Configuring ESLint" {
@"
import { FlatCompat } from "@eslint/eslintrc";
import js from "@eslint/js";
import tsParser from "@typescript-eslint/parser";
import prettier from "eslint-plugin-prettier";
import simpleImportSort from "eslint-plugin-simple-import-sort";
import unusedImports from "eslint-plugin-unused-imports";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: js.configs.recommended,
  allConfig: js.configs.all,
});

const config = [
  {
    ignores: ["**/next-env.d.ts"],
  },
  ...compat.extends(
    "next",
    "next/core-web-vitals",
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "prettier"
  ),
  {
    plugins: {
      "unused-imports": unusedImports,
      prettier,
      "simple-import-sort": simpleImportSort,
    },
    languageOptions: {
      parser: tsParser,
    },
    rules: {
      semi: "error",
      "react/no-unescaped-entities": "off",
      "react/jsx-uses-react": "off",
      "react/react-in-jsx-scope": "off",
      "@typescript-eslint/no-shadow": ["error"],
      "@typescript-eslint/no-use-before-define": ["error"],
      "no-use-before-define": "off",
      "no-await-in-loop": "warn",
      "no-eval": "error",
      "no-implied-eval": "error",
      "prefer-promise-reject-errors": "warn",
      "spaced-comment": "error",
      "no-duplicate-imports": "error",
      "no-explicit-any": "off",
      "@typescript-eslint/no-explicit-any": "off",
      "@typescript-eslint/no-unused-vars": "off",
      "no-unused-vars": "off",
      "react-hooks/exhaustive-deps": "off",
      "unused-imports/no-unused-imports": "error",
      "unused-imports/no-unused-vars": [
        "error",
        {
          vars: "all",
          varsIgnorePattern: "^_",
          args: "after-used",
          argsIgnorePattern: "^_"
        }
      ],
      "simple-import-sort/imports": [
        "error",
        {
          groups: [["^\\u0000", "^@?w"], ["^@/"], ["^."], ["^.+.(css|scss)$"]]
        }
      ],
      "simple-import-sort/exports": "error",
      "import/no-named-as-default-member": "warn"
    }
  }
];

export default config;
"@ | Set-Content "eslint.config.mjs"
}

# --- STEP 4: Husky ---

Run-Step "Configuring Husky" {
    if ($PACKAGE_MANAGER -eq "pnpm") {
        pnpm exec husky init
    } else {
        npx husky init
    }
    if (-not (Test-Path ".husky")) { New-Item -ItemType Directory -Path ".husky" | Out-Null }
    "$PACKAGE_MANAGER lint" | Set-Content ".husky/pre-commit"
}

# --- STEP 5: Project cleanup ---

Run-Step "Cleaning project structure" {
    Remove-Item -Recurse -Force "public" -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path "src/app" -Force | Out-Null

@'
@import "tailwindcss";
'@ | Set-Content "src/app/globals.css"

@'
import type { Metadata } from "next";
import "./globals.css";
import { PropsWithChildren } from "react";

export const metadata: Metadata = {
  title: "Create Next App",
};

export default function RootLayout({ children }: Readonly<PropsWithChildren>) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
'@ | Set-Content "src/app/layout.tsx"

"export default function Page() {
  return <>Home</>;
}" | Set-Content "src/app/page.tsx"
"export default function Page() {
  return <>Not found</>;
}" | Set-Content "src/app/not-found.tsx"
}

# --- STEP 6: .env + gitignore ---

Run-Step "Updating additional files" {
    if (-not (Select-String -Quiet "^!.env.example$" ".gitignore")) {
        Add-Content ".gitignore" "`n!.env.example"
    }
@"
# Example of .env file
#
# Copy this file content to .env and fill in the values
# This file is used as example and should not be used in production
"@ | Set-Content ".env.example"
}

# --- STEP 7: ESLint fix + scripts ---

Run-Step "Fixing code using ESLint" {
    if ($PACKAGE_MANAGER -eq "pnpm") {
        pnpm exec eslint "src/**/*.{ts,tsx}" --fix
    } elseif ($PACKAGE_MANAGER -eq "yarn") {
        yarn exec eslint "src/**/*.{ts,tsx}" --fix
    } else {
        npx eslint "src/**/*.{ts,tsx}" --fix
    }
}

# Update package.json
& npx json -I -f package.json -e 'this.scripts.lint="eslint \"src/**/*.{ts,tsx}\""' | Out-Null
& npx json -I -f package.json -e 'this.scripts["start:dev"]="next dev --turbopack"' | Out-Null

# --- STEP 8: Git commit ---

Run-Step "Committing changes to Git" {
    if ($GIT_COMMIT -eq "yes") {
        git add --all -- ":!prepare.ps1" | Out-Null
        git commit -m "chore: project prepared" | Out-Null
    }
}

Write-Host "`n✅ Project prepared successfully!"
Remove-Item $MyInvocation.MyCommand.Path -Force