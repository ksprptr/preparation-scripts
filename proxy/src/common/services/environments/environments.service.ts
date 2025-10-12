import { Logger } from '@nestjs/common';
import * as Table from 'cli-table3';
import * as dotenv from 'dotenv';
import * as fs from 'fs';
import * as path from 'path';

/**
 * Class representing an environments service
 */
export class EnvironmentsService {
  private readonly logger = new Logger(EnvironmentsService.name);

  /**
   * Function to check an environment file
   */
  public check() {
    this.logger.log('Checking environment file...');

    const table = new Table({ head: ['Missing key', 'Example'], style: { head: ['cyan'] } });
    const envExample = this.loadEnvExample();
    const envExampleKeys = Object.keys(envExample);

    envExampleKeys.map((key) => {
      const exampleValue = envExample[key];

      if (!process.env[key]) {
        return table.push([key, exampleValue]);
      }
    });

    this.logger.log('Environment file checked!');

    if (table.length > 0) {
      console.log(table.toString());
      this.logger.error('Some environment variables are missing! Please check the table above.');

      process.exit(1);
    }
  }

  /**
   * Function to load an example of the environment file
   */
  private loadEnvExample(): Record<string, string> {
    const envExamplePath = path.resolve(process.cwd(), '.env.example');

    try {
      const fileContent = fs.readFileSync(envExamplePath, 'utf-8');
      return dotenv.parse(fileContent);
    } catch (error) {
      this.logger.error(`Failed to load .env.example file: ${error.message}`);
      this.logger.error(
        'Some environment variables can be missing. Please add the .env.example file to the root of the project or check the .env file manually.',
      );

      return {};
    }
  }
}
