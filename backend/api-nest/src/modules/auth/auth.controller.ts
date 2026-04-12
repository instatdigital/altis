import {
  Controller,
  Post,
  Get,
  Body,
  Res,
  HttpCode,
  HttpStatus,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiCookieAuth } from '@nestjs/swagger';
import { Response } from 'express';
import { AuthService } from './auth.service';
import { AppleExchangeDto } from './dto/apple-exchange.dto';
import { AuthGuard } from './guards/auth.guard';
import {
  CurrentUser,
  AuthenticatedUser,
} from './decorators/current-user.decorator';

const COOKIE_NAME = 'session';
const COOKIE_MAX_AGE = 30 * 24 * 60 * 60 * 1000; // 30 days in ms

function sessionCookieOptions(maxAge: number) {
  return {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict' as const,
    path: '/',
    maxAge,
  };
}

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('apple/exchange')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Exchange Apple identity token for session cookie' })
  async appleExchange(
    @Body() dto: AppleExchangeDto,
    @Res({ passthrough: true }) res: Response,
  ): Promise<{ ok: boolean }> {
    const token = await this.authService.exchange(dto.identityToken);
    res.cookie(COOKIE_NAME, token, sessionCookieOptions(COOKIE_MAX_AGE));
    return { ok: true };
  }

  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(AuthGuard)
  @ApiCookieAuth('session')
  @ApiOperation({ summary: 'Revoke session and clear cookie' })
  async logout(
    @CurrentUser() user: AuthenticatedUser,
    @Res({ passthrough: true }) res: Response,
  ): Promise<void> {
    await this.authService.revokeSession(user.sessionId);
    res.clearCookie(COOKIE_NAME, { path: '/' });
  }

  @Get('session')
  @UseGuards(AuthGuard)
  @ApiCookieAuth('session')
  @ApiOperation({ summary: 'Return current user from session cookie' })
  async session(@CurrentUser() user: AuthenticatedUser) {
    const dbUser = await this.authService.getSessionUser(user.userId);
    return {
      userId: dbUser.id,
      appleId: dbUser.appleId,
      email: dbUser.email,
      name: dbUser.name,
    };
  }
}
