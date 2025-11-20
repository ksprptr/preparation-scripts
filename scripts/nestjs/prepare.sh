#!/bin/bash

# NestJS Preparation Script
# Description: Automates initial setup for a NestJS project
# Warning: This script modify and delete files in your project. Run it at your own risk. Always use a clean Git state or backup. Author is not responsible for any data loss.
# Author: Petr Kašpar
# License: MIT

#region Checks and project setup
if [ ! -d "node_modules/@nestjs" ]; then
    echo "> Not a NestJS project. Please create a project first."
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

echo "> Preparing NestJS project..."

#region Install dependencies
RUNTIME_PACKAGES=(
  cli-table3 dotenv @nestjs/config @nestjs/swagger swagger-themes class-transformer class-validator
)
DEV_PACKAGES=(
  @typescript-eslint/eslint-plugin @typescript-eslint/parser cross-env eslint-config-prettier eslint-plugin-import eslint-plugin-prettier eslint-plugin-simple-import-sort eslint-plugin-unused-imports husky
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
import { getEnvString } from 'src/common/utils/env.functions';

/**
 * Class representing an app config
 */
export class AppConfig {
  // API settings
  public static readonly API_GLOBAL_PREFIX = '/api/v1';

  // Is production environment?
  public static readonly isProduction = getEnvString('NODE_ENV') === 'production';
}
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
  "bracketSameLine": true
}
EOL

cat > .prettierignore <<EOL
.husky
.prettierignore
.stylelintignore
coverage
node_modules
EOL

cat > eslint.config.mjs <<EOL
import { FlatCompat } from '@eslint/eslintrc';
import js from '@eslint/js';
import typescriptEslintEslintPlugin from '@typescript-eslint/eslint-plugin';
import tsParser from '@typescript-eslint/parser';
import eslintPluginImport from 'eslint-plugin-import';
import prettier from 'eslint-plugin-prettier';
import simpleImportSort from 'eslint-plugin-simple-import-sort';
import unusedImports from 'eslint-plugin-unused-imports';
import globals from 'globals';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: js.configs.recommended,
  allConfig: js.configs.all,
});

const config = [
  {
    ignores: ['**/.eslintrc.js'],
  },
  ...compat.extends(
    'plugin:@typescript-eslint/recommended',
    'plugin:prettier/recommended',
    'prettier',
  ),
  {
    plugins: {
      '@typescript-eslint': typescriptEslintEslintPlugin,
      'unused-imports': unusedImports,
      prettier,
      'simple-import-sort': simpleImportSort,
      import: eslintPluginImport,
    },

    languageOptions: {
      globals: {
        ...globals.node,
        ...globals.jest,
      },

      parser: tsParser,
      ecmaVersion: 5,
      sourceType: 'module',

      parserOptions: {
        project: 'tsconfig.json',
      },
    },

    rules: {
      semi: 'error',
      '@typescript-eslint/no-shadow': ['error'],
      '@typescript-eslint/no-use-before-define': ['error'],
      '@typescript-eslint/interface-name-prefix': 'off',
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/explicit-module-boundary-types': 'off',
      '@typescript-eslint/no-explicit-any': 'off',
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
          groups: [['^\\u0000', '^@?\\w'], ['^@/'], ['^\\.'], ['^.+\\.(css|scss)$']],
        },
      ],
      'simple-import-sort/exports': 'error',
      'import/no-named-as-default-member': 'warn',
    },
  },
];

export default config;
EOL

cat > .env.example <<EOL
# Example of .env file
# 
# Copy this file content to .env and fill in the values
# This file is used as example and should not be used in production

# Ports
PORT=4000

# CORS
CORS_ORIGINS="http://localhost:3000,http://localhost:4000"
EOL

cat > .husky/pre-commit <<EOL
$PACKAGE_MANAGER lint
EOL
#endregion

#region Create additional files and folders
mkdir -p src/common/utils
mkdir -p src/common/services/environments
mkdir -p src/common/filters

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

cat > src/common/services/environments/environments.service.ts <<EOL
import { Logger } from "@nestjs/common";
import Table from "cli-table3";
import * as dotenv from "dotenv";
import * as fs from "fs";
import * as path from "path";
import { getEnvString } from "src/common/utils/env.functions";

/**
 * Class representing an environments service
 */
export class EnvironmentsService {
  private readonly logger = new Logger(EnvironmentsService.name);

  /**
   * Function to check an environment file
   */
  public check() {
    this.logger.log("Checking environment file...");

    const table = new Table({ head: ["Missing key", "Example"], style: { head: ["cyan"] } });
    const envExample = this.loadEnvExample();
    const envExampleKeys = Object.keys(envExample);

    envExampleKeys.map((key) => {
      const exampleValue = envExample[key];

      if (!process.env[key]) {
        return table.push([key, exampleValue]);
      }
    });

    this.logger.log("Environment file checked!");
    this.logger.log(\`Using \${getEnvString("NODE_ENV")} environment\`);

    if (table.length > 0) {
      console.log(table.toString());
      this.logger.error("Some environment variables are missing! Please check the table above.");

      process.exit(1);
    }
  }

  /**
   * Function to load an example of the environment file
   */
  private loadEnvExample(): Record<string, string> {
    const envExamplePath = path.resolve(process.cwd(), ".env.example");

    try {
      const fileContent = fs.readFileSync(envExamplePath, "utf-8");
      return dotenv.parse(fileContent);
    } catch (error) {
      this.logger.error(\`Failed to load .env.example file: \${error.message}\`);
      this.logger.error(
        "Some environment variables can be missing. Please add the .env.example file to the root of the project or check the .env file manually.",
      );

      return {};
    }
  }
}
EOL

cat > src/common/filters/exception.filter.ts <<EOL
import { ArgumentsHost, Catch, ExceptionFilter, HttpException, Logger } from '@nestjs/common';
import { Request, Response } from 'express';

/**
 * Class representing a global exception filter
 */
@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(GlobalExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    // Handle CSRF error (don't log as error)
    const isCsrfError =
      typeof exception === 'object' &&
      exception !== null &&
      'code' in exception &&
      (exception as any).code === 'EBADCSRFTOKEN';

    if (isCsrfError) {
      this.logger.warn(
        \`CSRF violation blocked: \${request.method} \${request.url} from \${request.ip}\`,
      );

      return response.status(403).json({ status: 403, message: 'Invalid CSRF token' });
    }

    // Handle HttpExceptions (thrown explicitly, e.g. ConflictException, NotFoundException, etc.)
    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const exceptionResponse = exception.getResponse();

      const message =
        typeof exceptionResponse === 'object' && exceptionResponse !== null
          ? (exceptionResponse as any).message || 'An error occurred'
          : String(exceptionResponse);

      const logFn = status >= 500 ? this.logger.error : this.logger.warn;
      logFn.call(\`[\${status}] \${request.method} \${request.url} - \${JSON.stringify(message)}\`);

      return response.status(status).json({ status, message });
    }

    // Handle unknown errors (runtime, Prisma, etc.)
    this.logger.error(
      \`Unhandled exception at \${request.method} \${request.url} from \${request.ip}\`,
      exception instanceof Error ? exception : String(exception),
    );

    return response.status(500).json({ status: 500, message: 'An unexpected error occurred' });
  }
}
EOL
#endregion

#region Update application files
mkdir -p src/api

mv src/app.controller.ts src/api/app.controller.ts
mv src/app.service.ts src/api/app.service.ts

cat > src/main.ts <<EOL
import { AppModule } from './app.module';
import { GlobalExceptionFilter } from './common/filters/exception.filter';
import { EnvironmentsService } from './common/services/environments/environments.service';
import { getEnvNumber, getEnvString } from './common/utils/env.functions';
import { AppConfig } from './configs/app.config';
import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { SwaggerTheme, SwaggerThemeNameEnum } from 'swagger-themes';

/**
 * Bootstrap function to initialize and configure the NestJS application
 */
async function bootstrap() {
  new EnvironmentsService().check();

  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Trust Proxy Configuration
  app.set('trust proxy', 1);

  // Global Prefix Configuration
  app.setGlobalPrefix(AppConfig.API_GLOBAL_PREFIX);

  // CORS Configuration
  app.enableCors({
    origin: getEnvString('CORS_ORIGINS')
      .split(',')
      .map((url) => url.trim()),
    methods: 'GET,HEAD,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
    exposedHeaders: ['accessToken', 'refreshToken'],
  });

  // Swagger Documentation
  if (getEnvString('NODE_ENV') === 'development') {
    const config = new DocumentBuilder().setTitle('NestJS API').build();
    const documentFactory = () => SwaggerModule.createDocument(app, config);

    const theme = new SwaggerTheme();
    const darkThemeOptions = {
      explorer: true,
      customCss: theme.getBuffer(SwaggerThemeNameEnum.DARK),
    };

    SwaggerModule.setup('swagger', app, documentFactory, { jsonDocumentUrl: 'swagger/json' });
    SwaggerModule.setup('swagger/dark', app, documentFactory, darkThemeOptions);
  }

  // Global Validation Pipe and Exception Filter
  app.useGlobalPipes(
    new ValidationPipe({
      always: true,
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  app.useGlobalFilters(new GlobalExceptionFilter());

  // Start the Application
  await app.listen(getEnvNumber('PORT'));
}

bootstrap();
EOL

cat > src/app.module.ts <<EOL
import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";

import { AppController } from "./api/app.controller";
import { AppService } from "./api/app.service";

/**
 * Class representing an app module
 */
@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true })],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
EOL
#endregion

#region Remove tests and update package.json scripts
rm -r test/ > /dev/null 2>&1 || true
find src -type f \( -name "*.spec.ts" -o -name "*.test.ts" \) -exec rm -f {} +
find src -type f \( -name "*.spec.tsx" -o -name "*.test.tsx" \) -exec rm -f {} +
npx json -I -f package.json -e "this.version=\"0.1.0\"" > /dev/null 2>&1
npx json -I -f package.json -e "this.scripts.lint=\"eslint 'src/**/*.{ts,tsx}' --fix\"" > /dev/null 2>&1
npx json -I -f package.json -e "this.scripts.start=\"cross-env NODE_ENV=production nest start\"" > /dev/null 2>&1
npx json -I -f package.json -e "this.scripts['start:dev']=\"cross-env NODE_ENV=development nest start --watch\"" > /dev/null 2>&1
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
EXPOSE 4000

# Start the application
CMD ["node", "dist/main.js"]
EOL

cat > docker-compose.yml <<EOL
services:
  app:
    build: .
    ports:
      - "4000:4000"
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