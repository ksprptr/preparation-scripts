#!/usr/bin/env pwsh
<#
Next.js Preparation Script
Description: Automates initial setup for a Next.js project
Warning: This script modifies and deletes files in your project. Run it at your own risk.
Author: Petr Kašpar
License: MIT
#>

# --- Function: RunStep ------------------------------------------------------
function RunStep {
    param (
        [string]$Message,
        [scriptblock]$Action
    )

    Write-Host "$Message..."
    try {
        & $Action | Out-Null
        Write-Host "$Message - Done!"
    } catch {
        Write-Host "$Message - FAILED: $($_.Exception.Message)"
        exit 1
    }
}

# --- Check Next.js Installation ----------------------------------------------
if (-not (Test-Path "node_modules/next")) {
    Write-Host "Not a Next.js project. Please create one first."
    exit 1
}

# --- Detect Package Manager --------------------------------------------------
if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    $PACKAGE_MANAGER = "pnpm"
} elseif (Get-Command yarn -ErrorAction SilentlyContinue) {
    $PACKAGE_MANAGER = "yarn"
} else {
    $PACKAGE_MANAGER = "npm"
}

Write-Host "Detected package manager: $PACKAGE_MANAGER"

# --- Check Git Repository ----------------------------------------------------
if (-not (Test-Path ".git")) {
    Write-Host "Git repository not initialized. Skipping git checks."
    $GIT_COMMIT = "no"
} else {
    $status = git status --porcelain | Select-String -NotMatch 'prepare.ps1'
    if ($status) {
        Write-Host "You have uncommitted changes. Please commit or stash them before running this script. (ignore prepare.ps1)"
        exit 1
    } else {
        $choice = Read-Host "We have detected a Git repository, do you want to commit the changes after preparation? (Y/n)"
        if ($choice -match '^[Nn]$') {
            $GIT_COMMIT = "no"
        } else {
            $GIT_COMMIT = "yes"
        }
    }
}

Clear-Host

# --- Step 1: Install dev packages --------------------------------------------
RunStep "Installing development packages" {
    $devPackages = @(
        "@typescript-eslint/eslint-plugin", "@typescript-eslint/parser",
        "eslint-config-prettier", "eslint-plugin-import", "eslint-plugin-prettier",
        "eslint-plugin-react", "eslint-plugin-react-hooks", "eslint-plugin-simple-import-sort",
        "eslint-plugin-unused-imports", "husky", "prettier", "prettier-plugin-tailwindcss"
    )

    if ($PACKAGE_MANAGER -eq "pnpm") {
        pnpm add -D $devPackages > $null 2>&1
        pnpm up --latest > $null 2>&1
    } elseif ($PACKAGE_MANAGER -eq "yarn") {
        yarn add -D $devPackages > $null 2>&1
        yarn upgrade --latest > $null 2>&1
    } else {
        npm install -D $devPackages > $null 2>&1
        npx npm-check-updates -u > $null 2>&1
        npm install > $null 2>&1
    }
}

# --- Step 2: Prettier Config -------------------------------------------------
RunStep "Configuring Prettier" {
@'
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
'@ | Out-File .prettierrc -Encoding utf8

@'
.next
.husky
.prettierignore
.stylelintignore
coverage
node_modules
public
'@ | Out-File .prettierignore -Encoding utf8
}

# --- Step 3: ESLint Config ---------------------------------------------------
RunStep "Configuring ESLint" {
@'
import tsPlugin from "@typescript-eslint/eslint-plugin";
import tsParser from "@typescript-eslint/parser";
import { defineConfig } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import prettier from "eslint-plugin-prettier";
import simpleImportSort from "eslint-plugin-simple-import-sort";
import unusedImports from "eslint-plugin-unused-imports";

export default defineConfig([
  ...nextVitals,
  {
    languageOptions: { parser: tsParser },
    plugins: {
      prettier,
      "unused-imports": unusedImports,
      "simple-import-sort": simpleImportSort,
      "@typescript-eslint": tsPlugin,
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
        { "vars": "all", "varsIgnorePattern": "^_", "args": "after-used", "argsIgnorePattern": "^_" }
      ],
      "simple-import-sort/imports": [
        "error",
        { "groups": [["^\\u0000", "^@?w"], ["^@/"], ["^."], ["^.+.(css|scss)$"]] }
      ],
      "simple-import-sort/exports": "error",
      "import/no-named-as-default-member": "warn"
    }
  }
]);
'@ | Out-File eslint.config.mjs -Encoding utf8
}

# --- Step 4: Husky -----------------------------------------------------------
RunStep "Configuring Husky" {
    if ($PACKAGE_MANAGER -eq "pnpm") {
        pnpm exec husky init > $null 2>&1
    } else {
        npx husky init > $null 2>&1
    }

    if (-not (Test-Path ".husky")) { New-Item -ItemType Directory -Path ".husky" | Out-Null }
    "$PACKAGE_MANAGER lint" | Out-File ".husky/pre-commit" -Encoding utf8
}

# --- Step 5: Clean project structure ----------------------------------------
RunStep "Cleaning project structure" {
    Remove-Item -Recurse -Force "public" -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path "src/app" -Force | Out-Null

@'
@import "tailwindcss";
'@ | Out-File src/app/globals.css -Encoding utf8

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
'@ | Out-File src/app/layout.tsx -Encoding utf8

@'
export default function Page() {
  return <>Home</>;
}
'@ | Out-File src/app/page.tsx -Encoding utf8

@'
export default function Page() {
  return <>Not found</>;
}
'@ | Out-File src/app/not-found.tsx -Encoding utf8
}

# --- Step 6: Update Additional Files ----------------------------------------
RunStep "Updating additional files" {
    if (Test-Path ".gitignore") {
        if (-not (Select-String -Path ".gitignore" -Pattern "^!.env.example$" -Quiet)) {
            "`n!.env.example" | Add-Content .gitignore
        }
    }

@'
# Example of .env file
# Copy this file content to .env and fill in the values
# This file is used as example and should not be used in production
'@ | Out-File .env.example -Encoding utf8
}

# --- Step 7: ESLint Fix -----------------------------------------------------
RunStep "Fixing code using ESLint" {
    if ($PACKAGE_MANAGER -eq "pnpm") {
        pnpm exec eslint "src/**/*.{ts,tsx}" --fix > $null 2>&1
    } elseif ($PACKAGE_MANAGER -eq "yarn") {
        yarn exec eslint "src/**/*.{ts,tsx}" --fix > $null 2>&1
    } else {
        npx eslint "src/**/*.{ts,tsx}" --fix > $null 2>&1
    }

    & npx json -I -f package.json -e 'this.scripts.lint="eslint \"src/**/*.{ts,tsx}\" --fix"' | Out-Null
    & npx json -I -f package.json -e 'this.scripts["start:dev"]="next dev"' | Out-Null
}

# --- Step 8: Commit ----------------------------------------------------------
if ($GIT_COMMIT -eq "yes") {
    RunStep "Committing changes to Git" {
        git add --all -- ":!prepare.ps1" > $null 2>&1
        git commit -m "chore: project prepared" > $null 2>&1
    }
}

# --- Finish -----------------------------------------------------------------
Write-Host "Project prepared successfully!"
Remove-Item $MyInvocation.MyCommand.Path -Force