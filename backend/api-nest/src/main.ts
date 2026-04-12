import 'reflect-metadata';
import { NestFactory, Reflector } from '@nestjs/core';
import {
  ValidationPipe,
  ClassSerializerInterceptor,
  Logger,
} from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
// eslint-disable-next-line @typescript-eslint/no-require-imports
const cookieParser = require('cookie-parser') as typeof import('cookie-parser');
import helmet from 'helmet';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    logger: ['error', 'warn', 'log', 'verbose'],
  });

  // Security
  app.use(helmet());
  app.use(cookieParser());

  // CORS — tightened in production via env
  app.enableCors({
    origin: process.env.CORS_ORIGIN ?? false,
    credentials: true,
  });

  // Global pipes & interceptors
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.useGlobalInterceptors(new ClassSerializerInterceptor(app.get(Reflector)));
  app.useGlobalFilters(new HttpExceptionFilter());

  // OpenAPI
  const docConfig = new DocumentBuilder()
    .setTitle('Altis API')
    .setDescription('Altis backend — online projects, boards, tasks')
    .setVersion('0.1.0')
    .addCookieAuth('session')
    .build();
  const document = SwaggerModule.createDocument(app, docConfig);
  SwaggerModule.setup('docs', app, document);

  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  Logger.log(`Altis API running on http://localhost:${port}`, 'Bootstrap');
  Logger.log(`OpenAPI docs: http://localhost:${port}/docs`, 'Bootstrap');
}

bootstrap();
