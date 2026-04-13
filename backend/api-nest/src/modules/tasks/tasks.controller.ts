import {
  Controller,
  Post,
  Put,
  Param,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiCookieAuth,
  ApiCreatedResponse,
  ApiOkResponse,
} from '@nestjs/swagger';
import { TasksService } from './tasks.service';
import { TaskDto } from './dto/task.dto';
import { CreateTaskDto } from './dto/create-task.dto';
import { UpdateTaskDto } from './dto/update-task.dto';
import { MoveTaskDto } from './dto/move-task.dto';
import { AuthGuard } from '../auth/guards/auth.guard';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../auth/decorators/current-user.decorator';

@ApiTags('tasks')
@ApiCookieAuth('session')
@UseGuards(AuthGuard)
@Controller()
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  @Post('projects/:projectId/tasks')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a project-scoped task' })
  @ApiCreatedResponse({ type: TaskDto })
  createForProject(
    @CurrentUser() user: AuthenticatedUser,
    @Param('projectId') projectId: string,
    @Body() dto: CreateTaskDto,
  ): Promise<TaskDto> {
    return this.tasksService.createForProject(user.userId, projectId, dto);
  }

  @Post('boards/:boardId/tasks')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a board-scoped task (placed in first regular stage by default)' })
  @ApiCreatedResponse({ type: TaskDto })
  createForBoard(
    @CurrentUser() user: AuthenticatedUser,
    @Param('boardId') boardId: string,
    @Body() dto: CreateTaskDto,
  ): Promise<TaskDto> {
    return this.tasksService.createForBoard(user.userId, boardId, dto);
  }

  @Put('tasks/:taskId')
  @ApiOperation({ summary: 'Update a task' })
  @ApiOkResponse({ type: TaskDto })
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('taskId') taskId: string,
    @Body() dto: UpdateTaskDto,
  ): Promise<TaskDto> {
    return this.tasksService.update(user.userId, taskId, dto);
  }

  @Post('tasks/:taskId/move')
  @ApiOperation({ summary: 'Move task to a different stage within the same board' })
  @ApiOkResponse({ type: TaskDto })
  move(
    @CurrentUser() user: AuthenticatedUser,
    @Param('taskId') taskId: string,
    @Body() dto: MoveTaskDto,
  ): Promise<TaskDto> {
    return this.tasksService.move(user.userId, taskId, dto);
  }

  @Post('tasks/:taskId/complete')
  @ApiOperation({ summary: 'Mark task as complete (moves to terminalSuccess stage if board-scoped)' })
  @ApiOkResponse({ type: TaskDto })
  complete(
    @CurrentUser() user: AuthenticatedUser,
    @Param('taskId') taskId: string,
  ): Promise<TaskDto> {
    return this.tasksService.complete(user.userId, taskId);
  }

  @Post('tasks/:taskId/fail')
  @ApiOperation({ summary: 'Mark task as failed (moves to terminalFailure stage if board-scoped)' })
  @ApiOkResponse({ type: TaskDto })
  fail(
    @CurrentUser() user: AuthenticatedUser,
    @Param('taskId') taskId: string,
  ): Promise<TaskDto> {
    return this.tasksService.fail(user.userId, taskId);
  }
}
