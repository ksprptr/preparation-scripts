import { Controller, Get, Param, Res } from '@nestjs/common';
import { Response } from 'express';
import { getEnvString } from 'src/common/utils/env.functions';

import { AppService } from './app.service';

/**
 * Class representing an app controller
 */
@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  private readonly githubRepoUrl = getEnvString('GITHUB_REPOSITORY_URL');

  /**
   * Controller to redirect to the github repo
   */
  @Get()
  get(@Res() res: Response) {
    return res.redirect(this.githubRepoUrl);
  }

  /**
   * Controller to get api status
   */
  @Get('status')
  async getStatus(@Res() res: Response) {
    return res.status(200).send({ statusCode: 200, message: 'API is running' });
  }

  /**
   * Controller to get a file from a github repository using a custom path
   */
  @Get('*path')
  async getFile(@Res() res: Response, @Param('path') path?: string[]) {
    if (!path?.length) {
      return res.redirect(this.githubRepoUrl);
    }

    const fileName = path.at(-1)?.toLowerCase();

    if (!fileName || fileName !== 'prepare.sh') {
      return res.redirect(this.githubRepoUrl);
    }

    const filePath = [...path.slice(0, -1), fileName].join('/');
    const buffer = await this.appService.getFileBuffer(filePath);

    if (!buffer) {
      return res.redirect(this.githubRepoUrl);
    }

    res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
    res.setHeader('Content-Type', 'application/x-sh');

    return res.send(buffer);
  }
}
