# Preparation Scripts Proxy

> API for redirecting to raw preparation scripts from GitHub.

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Run](#run)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [License](#license)

## Prerequisites

- Knowledge of JavaScript/TypeScript, [NestJS](https://nestjs.com/), Git
- IDE ([VS Code](https://code.visualstudio.com/), WebStorm, ...)
- Package manager ([pnpm (recommended)](https://pnpm.io/installation), npm, ...)

## Installation

1. Go to the project folder: `cd preparation-scripts/proxy/`
2. Install all dependecies: `pnpm install`
3. Copy `.env.example` to `.env` and update the properties accordingly
   - **Windows (CMD):** `copy .env.example .env`, **Linux/macOS:** `cp .env.example .env`

## Run

- Development server: `pnpm run start:dev`
- Debugging: `pnpm run start:debug`
- Production: `pnpm run start:prod`

## Configuration

> Server

| Description       | Values                 |
| ----------------- | ---------------------- |
| **Ports:**        | 4000                   |
| **Technologies:** | NestJS                 |
| **URL:**          | http://localhost:4000/ |

## Deployment

| Description | Values                      |
| ----------- | --------------------------- |
| **Server:** | Coolify                     |
| **URL:**    | https://scripts.ksprptr.dev |

## License

> This software is developed by **Petr Kašpar** and is licensed under the MIT License.  
> For more details, please refer to the LICENSE file.
