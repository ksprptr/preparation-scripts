import { NestFactory } from '@nestjs/core';

import { AppModule } from './app.module';
import { EnvironmentsService } from './common/services/environments/environments.service';
import { getEnvNumber } from './common/utils/env.functions';

/**
 * Bootstrap function to initialize and configure the NestJS application
 */
async function bootstrap() {
  new EnvironmentsService().check();

  const app = await NestFactory.create(AppModule);

  await app.listen(getEnvNumber('PORT'));
}

bootstrap();
