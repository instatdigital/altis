import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiCookieAuth } from '@nestjs/swagger';
import { AuthGuard } from '../auth/guards/auth.guard';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../auth/decorators/current-user.decorator';
import { ProfileService } from './profile.service';
import { ProfileDto } from './dto/profile.dto';

@ApiTags('profile')
@Controller('profile')
export class ProfileController {
  constructor(private readonly profileService: ProfileService) {}

  @Get('me')
  @UseGuards(AuthGuard)
  @ApiCookieAuth('session')
  @ApiOperation({ summary: 'Return the authenticated user profile' })
  me(@CurrentUser() user: AuthenticatedUser): Promise<ProfileDto> {
    return this.profileService.getMe(user.userId);
  }
}
