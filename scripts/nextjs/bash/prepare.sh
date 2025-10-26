#!/bin/bash

# Next.js Preparation Script
# Description: Automates initial setup for a Next.js project
# Warning: This script modify and delete files in your project. Run it at your own risk. Always use a clean Git state or backup. Author is not responsible for any data loss.
# Author: Petr Kašpar
# License: MIT

# Function: show progress bar while command runs
show_progress_during() {
  local message=$1
  shift
  echo -n "$message "

  ("$@" > /dev/null 2>&1) &
  local pid=$!
  local spin='|/-\'
  local i=0

  while kill -0 "$pid" 2>/dev/null; do
    i=$(( (i+1) %4 ))
    printf "\r$message [${spin:$i:1}]"
    sleep 0.1
  done

  wait "$pid"
  printf "\r$message [✓] Done!\n"
}

# Check Next.js installation
if [ ! -d "node_modules/next" ]; then
    echo "Not a Next.js project. Please create one first."
    exit 1
fi

# Detect package manager
if command -v pnpm &> /dev/null; then
    PACKAGE_MANAGER="pnpm"
elif command -v yarn &> /dev/null; then
    PACKAGE_MANAGER="yarn"
else
    PACKAGE_MANAGER="npm"
fi

echo "Detected package manager: $PACKAGE_MANAGER"

# Check Git repository
if [ ! -d ".git" ]; then
    echo "Git repository not initialized. Skipping git checks."
    GIT_COMMIT="no"
else
    if [ -n "$(git status --porcelain | grep -v 'prepare.sh')" ]; then
        echo "You have uncommitted changes. Please commit or stash them before running this script. (ignore prepare.sh)"
        exit 1
    else
        read -p "We have detected a Git repository, do you want to commit the changes after preparation? (Y/n): " choice
        case "$choice" in
            n|N ) GIT_COMMIT="no";;
            * ) GIT_COMMIT="yes";;
        esac
    fi
fi

clear

# Step 1: Install development packages
show_progress_during "Installing development packages" bash -c '
  PACKAGE_MANAGER="'"$PACKAGE_MANAGER"'"
  DEV_PACKAGES=(
    @typescript-eslint/eslint-plugin @typescript-eslint/parser eslint-config-prettier eslint-plugin-import eslint-plugin-prettier eslint-plugin-react eslint-plugin-react-hooks eslint-plugin-simple-import-sort eslint-plugin-unused-imports husky prettier prettier-plugin-tailwindcss
  )

  if [ "$PACKAGE_MANAGER" = "pnpm" ]; then
      pnpm add -D "${DEV_PACKAGES[@]}" && pnpm up --latest
  elif [ "$PACKAGE_MANAGER" = "yarn" ]; then
      yarn add -D "${DEV_PACKAGES[@]}" && yarn upgrade --latest
  else
      npm install -D "${DEV_PACKAGES[@]}"
      npx npm-check-updates -u && npm install
  fi
'

# Step 2: Setup Prettier config
show_progress_during "Configuring Prettier" bash -c '
cat > .prettierrc <<EOL
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
EOL

cat > .prettierignore <<EOL
.next
.husky
.prettierignore
.stylelintignore
coverage
node_modules
public
EOL
'

# Step 3: Setup ESLint config
show_progress_during "Configuring ESLint" bash -c 'true'

cat > eslint.config.mjs <<'EOL'
import tsPlugin from '@typescript-eslint/eslint-plugin';
import tsParser from '@typescript-eslint/parser';
import { defineConfig } from 'eslint/config';
import nextVitals from 'eslint-config-next/core-web-vitals';
import prettier from 'eslint-plugin-prettier';
import simpleImportSort from 'eslint-plugin-simple-import-sort';
import unusedImports from 'eslint-plugin-unused-imports';

export default defineConfig([
  ...nextVitals,
  {
    languageOptions: {
      parser: tsParser,
    },
    plugins: {
      prettier,
      'unused-imports': unusedImports,
      'simple-import-sort': simpleImportSort,
      '@typescript-eslint': tsPlugin,
    },
    rules: {
      semi: 'error',
      'react/no-unescaped-entities': 'off',
      'react/jsx-uses-react': 'off',
      'react/react-in-jsx-scope': 'off',
      '@typescript-eslint/no-shadow': ['error'],
      '@typescript-eslint/no-use-before-define': ['error'],
      'no-use-before-define': 'off',
      'no-await-in-loop': 'warn',
      'no-eval': 'error',
      'no-implied-eval': 'error',
      'prefer-promise-reject-errors': 'warn',
      'spaced-comment': 'error',
      'no-duplicate-imports': 'error',
      'no-explicit-any': 'off',
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/no-unused-vars': 'off',
      'no-unused-vars': 'off',
      'react-hooks/exhaustive-deps': 'off',
      'unused-imports/no-unused-imports': 'error',
      'unused-imports/no-unused-vars': [
        'error',
        {
          vars: 'all',
          varsIgnorePattern: '^_',
          args: 'after-used',
          argsIgnorePattern: '^_',
        },
      ],
      'simple-import-sort/imports': [
        'error',
        {
          groups: [['^\\u0000', '^@?w'], ['^@/'], ['^.'], ['^.+.(css|scss)$']],
        },
      ],
      'simple-import-sort/exports': 'error',
      'import/no-named-as-default-member': 'warn',
    },
  },
]);
EOL

# Step 4: Setup Husky pre-commit
show_progress_during "Configuring Husky" bash -c '
PACKAGE_MANAGER="'"$PACKAGE_MANAGER"'"

if [ "$PACKAGE_MANAGER" = "pnpm" ]; then
    pnpm exec husky init
else
    npx husky init
fi
mkdir -p .husky
cat > .husky/pre-commit <<EOL
$PACKAGE_MANAGER lint
EOL
'

# Step 5: Clean src/app and public
show_progress_during "Cleaning project structure" bash -c '
rm -rf public
mkdir -p src/app
cat > src/app/globals.css <<EOL
@import "tailwindcss";
EOL
cat > src/app/layout.tsx <<EOL
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
EOL
cat > src/app/page.tsx <<EOL
export default function Page() {
  return <>Home</>;
}
EOL
cat > src/app/not-found.tsx <<EOL
export default function Page() {
  return <>Not found</>;
}
EOL
'

# Step 6: Update additional files
show_progress_during "Updating additional files" bash -c '
if [ -f .gitignore ]; then
    if ! grep -q "^!.env.example$" .gitignore; then
        echo -e "\n!.env.example" >> .gitignore
    fi
fi

cat > .env.example <<EOL
# Example of .env file
# 
# Copy this file content to .env and fill in the values
# This file is used as example and should not be used in production
EOL
'

# Step 7: Code fix using ESLint
show_progress_during "Fixing code using ESLint" bash -c '
if [ "$PACKAGE_MANAGER" = "pnpm" ]; then
    pnpm exec eslint "src/**/*.{ts,tsx}" --fix
elif [ "$PACKAGE_MANAGER" = "yarn" ]; then
    yarn exec eslint "src/**/*.{ts,tsx}" --fix
else
    npx eslint "src/**/*.{ts,tsx}" --fix
fi
'

npx json -I -f package.json -e "this.scripts.lint=\"eslint 'src/**/*.{ts,tsx}' --fix\"" > /dev/null 2>&1
npx json -I -f package.json -e "this.scripts['start:dev']='next dev'" > /dev/null 2>&1

# Step 8: Commit changes to Git (if applicable)
if [ "$GIT_COMMIT" = "yes" ]; then
  show_progress_during "Committing changes to Git" bash -c '
    git add --all -- ":!prepare.sh" > /dev/null 2>&1
    git commit -m "chore: project prepared" > /dev/null 2>&1
  '
fi

# Final message
echo "Project prepared successfully!"

# Self-delete script
rm -- "$0"