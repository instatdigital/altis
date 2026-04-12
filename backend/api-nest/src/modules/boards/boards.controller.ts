import {
  Controller,
  Get,
  Post,
  Patch,
  Put,
  Delete,
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
  ApiOkResponse,
  ApiCreatedResponse,
} from '@nestjs/swagger';
import { BoardsService } from './boards.service';
import { BoardDto } from './dto/board.dto';
import { BoardStageDto } from './dto/board-stage.dto';
import { CreateBoardDto } from './dto/create-board.dto';
import { CreateStageDto } from './dto/create-stage.dto';
import { RenameStageDto } from './dto/rename-stage.dto';
import { ReorderStagesDto } from './dto/reorder-stages.dto';
import { AuthGuard } from '../auth/guards/auth.guard';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../auth/decorators/current-user.decorator';

@ApiTags('boards')
@ApiCookieAuth('session')
@UseGuards(AuthGuard)
@Controller()
export class BoardsController {
  constructor(private readonly boardsService: BoardsService) {}

  @Get('projects/:projectId/boards')
  @ApiOperation({ summary: 'List boards for a project' })
  @ApiOkResponse({ type: [BoardDto] })
  findByProject(
    @CurrentUser() user: AuthenticatedUser,
    @Param('projectId') projectId: string,
  ): Promise<BoardDto[]> {
    return this.boardsService.findByProject(user.userId, projectId);
  }

  @Post('projects/:projectId/boards')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a board in a project' })
  @ApiCreatedResponse({ type: BoardDto })
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Param('projectId') projectId: string,
    @Body() dto: CreateBoardDto,
  ): Promise<BoardDto> {
    return this.boardsService.create(user.userId, projectId, dto);
  }

  @Post('boards/:boardId/stages')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Add a regular stage to a board' })
  @ApiCreatedResponse({ type: BoardStageDto })
  createStage(
    @CurrentUser() user: AuthenticatedUser,
    @Param('boardId') boardId: string,
    @Body() dto: CreateStageDto,
  ): Promise<BoardStageDto> {
    return this.boardsService.createStage(user.userId, boardId, dto);
  }

  @Patch('boards/:boardId/stages/:stageId')
  @ApiOperation({ summary: 'Rename a stage' })
  @ApiOkResponse({ type: BoardStageDto })
  renameStage(
    @CurrentUser() user: AuthenticatedUser,
    @Param('boardId') boardId: string,
    @Param('stageId') stageId: string,
    @Body() dto: RenameStageDto,
  ): Promise<BoardStageDto> {
    return this.boardsService.renameStage(user.userId, boardId, stageId, dto);
  }

  @Put('boards/:boardId/stages/reorder')
  @ApiOperation({ summary: 'Reorder all stages of a board' })
  @ApiOkResponse({ type: [BoardStageDto] })
  reorderStages(
    @CurrentUser() user: AuthenticatedUser,
    @Param('boardId') boardId: string,
    @Body() dto: ReorderStagesDto,
  ): Promise<BoardStageDto[]> {
    return this.boardsService.reorderStages(user.userId, boardId, dto);
  }

  @Delete('boards/:boardId/stages/:stageId')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({
    summary:
      'Delete a non-terminal stage (moves tasks to first remaining regular stage)',
  })
  deleteStage(
    @CurrentUser() user: AuthenticatedUser,
    @Param('boardId') boardId: string,
    @Param('stageId') stageId: string,
  ): Promise<void> {
    return this.boardsService.deleteStage(user.userId, boardId, stageId);
  }
}
