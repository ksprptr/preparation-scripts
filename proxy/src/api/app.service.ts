import { Injectable } from '@nestjs/common';
import { getEnvString } from 'src/common/utils/env.functions';

/**
 * Class representing an app service
 */
@Injectable()
export class AppService {
  /**
   * Function to get a file buffer from a github repository using a custom path
   */
  async getFileBuffer(filePath: string): Promise<Buffer | null> {
    const url = `${getEnvString('GITHUB_REPOSITORY_URL')}/raw/${getEnvString('GITHUB_BRANCH')}/scripts/${filePath}`;

    const buffer = await fetch(url).then((res) => {
      if (res.status === 200) {
        return res.arrayBuffer().then((ab) => Buffer.from(ab));
      }

      return null;
    });

    return buffer;
  }
}
