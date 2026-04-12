import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('profile')
@Controller('profile')
export class ProfileController {
  @Get('me')
  @ApiOperation({ summary: 'Return the authenticated user profile' })
  me() {
    // Implemented in Task 6 (Wrap Up)
    return { status: 'not_implemented' };
  }
}
