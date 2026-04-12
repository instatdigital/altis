import { Controller, Get, Post, Param } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('boards')
@Controller()
export class BoardsController {
  @Get('projects/:projectId/boards')
  @ApiOperation({ summary: 'List boards for a project' })
  findByProject(@Param('projectId') _projectId: string) {
    // Implemented in Task 4 (Boards & Stages)
    return [];
  }

  @Post('projects/:projectId/boards')
  @ApiOperation({ summary: 'Create a board in a project' })
  create(@Param('projectId') _projectId: string) {
    // Implemented in Task 4 (Boards & Stages)
    return { status: 'not_implemented' };
  }
}
