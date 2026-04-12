import { Controller, Post, Get, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  @Post('apple/exchange')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Exchange Apple ID token for session cookie' })
  appleExchange() {
    // Implemented in Task 2 (Auth MVP)
    return { status: 'not_implemented' };
  }

  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Revoke session and clear cookie' })
  logout() {
    // Implemented in Task 2 (Auth MVP)
  }

  @Get('session')
  @ApiOperation({ summary: 'Return current user from session cookie' })
  session() {
    // Implemented in Task 2 (Auth MVP)
    return { status: 'not_implemented' };
  }
}
