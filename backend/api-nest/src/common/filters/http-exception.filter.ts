import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { Prisma } from '@prisma/client';

export interface ErrorEnvelope {
  statusCode: number;
  error: string;
  message: string | string[];
  path: string;
  timestamp: string;
}

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message: string | string[] = 'Internal server error';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const body = exception.getResponse();
      message =
        typeof body === 'object' && body !== null && 'message' in body
          ? (body as { message: string | string[] }).message
          : exception.message;
    } else if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      switch (exception.code) {
        case 'P2025':
          status = HttpStatus.NOT_FOUND;
          message = 'Resource not found';
          break;
        case 'P2002':
          status = HttpStatus.CONFLICT;
          message = 'Resource already exists';
          break;
        case 'P2003':
          status = HttpStatus.BAD_REQUEST;
          message = 'Invalid reference';
          break;
        default:
          status = HttpStatus.BAD_REQUEST;
          message = 'Database request error';
          this.logger.error(
            `Prisma error ${exception.code} on ${request.method} ${request.path}`,
            exception.message,
          );
      }
    } else if (exception instanceof Prisma.PrismaClientValidationError) {
      status = HttpStatus.BAD_REQUEST;
      message = 'Invalid request data';
      this.logger.error(
        `Prisma validation error on ${request.method} ${request.path}`,
        exception.message,
      );
    } else {
      this.logger.error(
        `Unhandled exception on ${request.method} ${request.path}`,
        exception instanceof Error ? exception.stack : String(exception),
      );
    }

    const envelope: ErrorEnvelope = {
      statusCode: status,
      error: HttpStatus[status] ?? 'UNKNOWN',
      message,
      path: request.path,
      timestamp: new Date().toISOString(),
    };

    response.status(status).json(envelope);
  }
}
