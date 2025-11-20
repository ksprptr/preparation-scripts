#!/bin/bash

# Next.js Preparation Script
# Description: Automates initial setup for a Next.js project
# Warning: This script modify and delete files in your project. Run it at your own risk. Always use a clean Git state or backup. Author is not responsible for any data loss.
# Author: Petr Kašpar
# License: MIT

#region Checks and project setup
if [ ! -d "node_modules/next" ]; then
    echo "> Not a Next.js project. Please create a project first."
    exit 1
fi

if command -v pnpm &> /dev/null; then
    PACKAGE_MANAGER="pnpm"
elif command -v yarn &> /dev/null; then
    PACKAGE_MANAGER="yarn"
else
    PACKAGE_MANAGER="npm"
fi

if [ ! -d ".git" ]; then
    GIT_COMMIT="no"
else
    if [ -n "$(git status --porcelain | grep -v 'prepare.sh')" ]; then
        echo "> Uncommitted changes found. Please commit or stash them before running this script. (ignore prepare.sh)"
        exit 1
    else
        read -p "> Git repository detected. Commit changes after preparation? (Y/n): " choice
        case "$choice" in
            n|N ) GIT_COMMIT="no";;
            * ) GIT_COMMIT="yes";;
        esac
    fi
fi

read -p "> Run the project inside a Docker container? (y/N): " docker_choice
case "$docker_choice" in
    y|Y ) USE_DOCKER="yes";;
    * ) USE_DOCKER="no";;
esac
#endregion

echo "> Preparing Next.js project..."

#region Install dependencies
RUNTIME_PACKAGES=()
DEV_PACKAGES=(
  @typescript-eslint/eslint-plugin @typescript-eslint/parser eslint-config-prettier eslint-plugin-import eslint-plugin-prettier eslint-plugin-react eslint-plugin-react-hooks eslint-plugin-simple-import-sort eslint-plugin-unused-imports husky prettier prettier-plugin-tailwindcss
)

if [ "$PACKAGE_MANAGER" = "pnpm" ]; then
    pnpm add "${RUNTIME_PACKAGES[@]}" > /dev/null 2>&1
    pnpm add -D "${DEV_PACKAGES[@]}" > /dev/null 2>&1
    pnpm up --latest > /dev/null 2>&1
elif [ "$PACKAGE_MANAGER" = "yarn" ]; then
    yarn add "${RUNTIME_PACKAGES[@]}" > /dev/null 2>&1
    yarn add -D "${DEV_PACKAGES[@]}" > /dev/null 2>&1
    yarn upgrade --latest > /dev/null 2>&1
else
    npm install "${RUNTIME_PACKAGES[@]}" > /dev/null 2>&1
    npm install -D "${DEV_PACKAGES[@]}" > /dev/null 2>&1
    npx npm-check-updates -u > /dev/null 2>&1 && npm install > /dev/null 2>&1
fi
#endregion

#region Configuration files setup
if [ "$PACKAGE_MANAGER" = "pnpm" ]; then
    pnpm exec husky init
else
    npx husky init
fi

if [ -f .gitignore ]; then
    if ! grep -q "^!.env.example$" .gitignore; then
        echo -e "\n!.env.example" >> .gitignore
    fi
fi

mkdir -p src/configs

cat > src/configs/app.config.ts <<EOL
import { MetadataConfig } from '@/common/types/metadata.types';
import { getEnvString } from '@/common/utils/env.functions';

import nextConfig from '../../next.config';

// Is production environment?
export const isProduction = getEnvString('NODE_ENV') === 'production';

// Allowed cdn hosts
export const allowedCdnHosts: string[] =
  nextConfig.images?.remotePatterns?.map((pattern) => pattern.hostname) || ([] as string[]);

/**
 * Web metadata configuration
 */
export const metadataConfig: MetadataConfig = {
  title: '',
  shortTitle: '',
  description: '',
  keywords: [],
  colors: {
    background: '#000000',
    theme: '#000000',
  },
};

/**
 * Function to get the environment url based on the environment
 */
export const getEnvUrl = (type: 'app' | 'api'): string => {
  const requireEnv = (varName: string) => {
    const value = getEnvString(varName);

    if (!value) {
      throw new Error(\`\${varName} is not defined in environment variables\`);
    }

    return value;
  };

  switch (type) {
    case 'app':
      return requireEnv('NEXT_PUBLIC_APP_URL');
    case 'api':
      return requireEnv('NEXT_PUBLIC_API_URL');
  }
};
EOL

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

cat > eslint.config.mjs <<EOL
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

cat > .env.example <<EOL
# Example of .env file
# 
# Copy this file content to .env and fill in the values
# This file is used as example and should not be used in production

# App URL
NEXT_PUBLIC_APP_URL="http://localhost:3000"

# API URL
NEXT_PUBLIC_API_URL="http://localhost:4000"
EOL

cat > .husky/pre-commit <<EOL
$PACKAGE_MANAGER lint
EOL
#endregion

#region Create additional files and folders
mkdir -p src/common/utils
mkdir -p src/common/types

cat > src/common/utils/env.functions.ts <<EOL
/**
* Function to get a string environment variable
*/
export const getEnvString = (key: string): string => {
  const value = process.env[key];

  if (!value) {
    throw new Error(\`Config value for key "\${key}" is not set\`);
  }

  return value;
};

/**
* Function to get a number environment variable
*/
export const getEnvNumber = (key: string): number => {
  const value = getEnvString(key);
  const numberValue = Number(value);

  if (isNaN(numberValue)) {
    throw new Error(\`Config value for key "\${key}" is not a number\`);
  }

  return numberValue;
};
EOL

cat > src/common/types/metadata.types.ts <<EOL
export interface MetadataConfig {
  title: string;
  shortTitle: string;
  description: string;
  keywords: string[];
  colors: {
    background: string;
    theme: string;
  };
}
EOL

cat > src/app/manifest.ts <<EOL
import { metadataConfig } from '@/configs/app.config';

import { MetadataRoute } from 'next';

/**
 * Function to generate a manifest file
 */
export default function Manifest(): MetadataRoute.Manifest {
  return {
    name: metadataConfig.title,
    short_name: metadataConfig.shortTitle,
    description: metadataConfig.description,
    start_url: '/',
    display: 'browser',
    background_color: metadataConfig.colors.background,
    theme_color: metadataConfig.colors.theme,
    icons: [
      {
        src: '/web-app-manifest-192x192.png',
        sizes: '192x192',
        type: 'image/png',
        purpose: 'maskable',
      },
      {
        src: '/web-app-manifest-512x512.png',
        sizes: '512x512',
        type: 'image/png',
        purpose: 'maskable',
      },
    ],
  };
}
EOL

cat > src/app/robots.ts <<EOL
import { getEnvUrl } from '@/configs/app.config';

import { MetadataRoute } from 'next';

/**
 * Function to generate a robots file
 */
export default function Robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: '*',
      allow: '/',
      disallow: [],
    },
    sitemap: \`\${getEnvUrl('app')}/sitemap.xml\`,
    host: getEnvUrl('app'),
  };
}
EOL

cat > src/app/sitemap.ts <<EOL
import { getEnvUrl } from '@/configs/app.config';

import { MetadataRoute } from 'next';

/**
 * Function to generate a sitemap file
 */
export default function Sitemap(): MetadataRoute.Sitemap {
  return [
    {
      url: getEnvUrl('app'),
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority: 1,
    },
  ];
}
EOL
#endregion

#region Update application files
rm -rf public

cat > src/app/globals.css <<EOL
@import "tailwindcss";
EOL

cat > src/app/layout.tsx <<EOL
import { getEnvUrl, metadataConfig } from '@/configs/app.config';

import { Metadata } from "next";
import { PropsWithChildren } from "react";

import "./globals.css";

// Web metadata
export const metadata: Metadata = {
  title: metadataConfig.title,
  description: metadataConfig.description,
  keywords: metadataConfig.keywords,
  openGraph: {
    title: metadataConfig.title,
    type: 'website',
    url: getEnvUrl('app'),
    siteName: metadataConfig.shortTitle,
    description: metadataConfig.description,
    images: [
      {
        url: '',
        width: 1200,
        height: 630,
        alt: metadataConfig.shortTitle,
      },
    ],
  },
  twitter: {
    title: metadataConfig.title,
    description: metadataConfig.description,
    images: [
      {
        url: '',
        width: 1200,
        height: 630,
        alt: metadataConfig.shortTitle,
      },
    ],
    card: 'summary_large_image',
  },
};

/**
 * Component representing a root layout
 */
export default function RootLayout({ children }: Readonly<PropsWithChildren>) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
EOL

cat > src/app/page.tsx <<EOL
/**
 * Component representing a home page
 */
export default function Page() {
  return <>Home</>;
}
EOL


cat > src/app/not-found.tsx <<EOL
/**
 * Component representing a not found page
 */
export default function Page() {
  return <>Not found</>;
}
EOL
#endregion

#region Update package.json scripts
npx json -I -f package.json -e "this.version=\"0.1.0\"" > /dev/null 2>&1
npx json -I -f package.json -e "this.scripts.lint=\"eslint 'src/**/*.{ts,tsx}' --fix\"" > /dev/null 2>&1
npx json -I -f package.json -e "this.scripts['start:dev']='next dev'" > /dev/null 2>&1
#endregion

#region Fix code style using ESLint
if [ "$PACKAGE_MANAGER" = "pnpm" ]; then
    pnpm exec eslint "src/**/*.{ts,tsx}" --fix
elif [ "$PACKAGE_MANAGER" = "yarn" ]; then
    yarn exec eslint "src/**/*.{ts,tsx}" --fix
else
    npx eslint "src/**/*.{ts,tsx}" --fix
fi
#endregion

#region Docker setup
if [ "$USE_DOCKER" = "yes" ]; then
    cat > .dockerignore <<EOL
node_modules
dist
EOL

    cat > Dockerfile <<EOL
# Use official Node.js LTS image
FROM node:22-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install pnpm
RUN npm install -g pnpm

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy .env file into build stage
COPY .env ./

# Copy application source code
COPY . .

# Build the application
RUN pnpm run build

# Expose application port
EXPOSE 3000

# Start the application
CMD ["node", "dist/main.js"]
EOL

cat > docker-compose.yml <<EOL
services:
  app:
    build: .
    ports:
      - "3000:3000"
    env_file:
      - .env
    volumes:
      - .:/app
      - /app/node_modules
    command: pnpm run start
EOL
fi
#endregion

#region Git commit changes
if [ "$GIT_COMMIT" = "yes" ]; then
  git add --all -- ":!prepare.sh" > /dev/null 2>&1
  git commit -m "chore: project prepared" > /dev/null 2>&1
fi
#endregion

# Final message and self-delete
echo "> Project prepared successfully."
rm -- "$0"