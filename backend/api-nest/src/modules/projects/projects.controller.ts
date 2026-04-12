import { Controller, Get, Post } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('projects')
@Controller('projects')
export class ProjectsController {
  @Get()
  @ApiOperation({ summary: 'List online projects for the authenticated user' })
  findAll() {
    // Implemented in Task 3 (Projects)
    return [];
  }

  @Post()
  @ApiOperation({ summary: 'Create an online project' })
  create() {
    // Implemented in Task 3 (Projects)
    return { status: 'not_implemented' };
  }
}
