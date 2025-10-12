import { NestFactory } from '@nestjs/core';

import { AppModule } from './api/app.module';
import { EnvironmentsService } from './common/services/environments/environments.service';

/**
 * Bootstrap function to initialize and configure the NestJS application
 */
async function bootstrap() {
  new EnvironmentsService().check();

  const app = await NestFactory.create(AppModule);

  await app.listen(process.env.PORT ?? 4000);
}

bootstrap();
