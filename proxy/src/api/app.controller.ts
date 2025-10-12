import { Controller, Get, Param, Res } from '@nestjs/common';
import { Response } from 'express';

import { AppService } from './app.service';

/**
 * Class representing an app controller
 */
@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  /**
   * Controller to redirect to the github repo
   */
  @Get()
  get(@Res() res: Response) {
    return res.redirect(process.env.GITHUB_REPOSITORY_URL!);
  }

  /**
   * Controller to get a file from a github repository using a custom path
   */
  @Get('*path')
  async getFile(@Res() res: Response, @Param('path') path?: string[]) {
    const githubRepoUrl = process.env.GITHUB_REPOSITORY_URL!;

    if (!path?.length) {
      return res.redirect(githubRepoUrl);
    }

    const fileName = path.at(-1)?.toLowerCase();
    const allowedFileNames = ['prepare.sh', 'prepare.ps1'];

    if (!fileName || !allowedFileNames.includes(fileName)) {
      return res.redirect(githubRepoUrl);
    }

    const scriptType = fileName.endsWith('.sh') ? 'bash' : 'powershell';
    const filePath = [...path.slice(0, -1), scriptType, fileName].join('/');
    const buffer = await this.appService.getFileBuffer(filePath);

    if (!buffer) {
      return res.redirect(githubRepoUrl);
    }

    const contentTypes: Record<string, string> = {
      bash: 'application/x-sh',
      powershell: 'application/x-powershell',
    };

    res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
    res.setHeader('Content-Type', contentTypes[scriptType]);

    return res.send(buffer);
  }
}
