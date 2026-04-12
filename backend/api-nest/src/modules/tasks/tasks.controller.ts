import { Controller, Post, Put, Param } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('tasks')
@Controller()
export class TasksController {
  @Post('projects/:projectId/tasks')
  @ApiOperation({ summary: 'Create a project-scoped task' })
  createForProject(@Param('projectId') _projectId: string) {
    // Implemented in Task 5 (Tasks)
    return { status: 'not_implemented' };
  }

  @Post('boards/:boardId/tasks')
  @ApiOperation({ summary: 'Create a board-scoped task' })
  createForBoard(@Param('boardId') _boardId: string) {
    // Implemented in Task 5 (Tasks)
    return { status: 'not_implemented' };
  }

  @Put('tasks/:taskId')
  @ApiOperation({ summary: 'Update a task' })
  update(@Param('taskId') _taskId: string) {
    // Implemented in Task 5 (Tasks)
    return { status: 'not_implemented' };
  }

  @Post('tasks/:taskId/move')
  @ApiOperation({ summary: 'Move task to a different stage' })
  move(@Param('taskId') _taskId: string) {
    // Implemented in Task 5 (Tasks)
    return { status: 'not_implemented' };
  }

  @Post('tasks/:taskId/complete')
  @ApiOperation({ summary: 'Mark task as complete (terminal success)' })
  complete(@Param('taskId') _taskId: string) {
    // Implemented in Task 5 (Tasks)
    return { status: 'not_implemented' };
  }

  @Post('tasks/:taskId/fail')
  @ApiOperation({ summary: 'Mark task as failed (terminal failure)' })
  fail(@Param('taskId') _taskId: string) {
    // Implemented in Task 5 (Tasks)
    return { status: 'not_implemented' };
  }
}
