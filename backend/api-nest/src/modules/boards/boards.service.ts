import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { BoardDto } from './dto/board.dto';
import { BoardStageDto } from './dto/board-stage.dto';
import { CreateBoardDto } from './dto/create-board.dto';
import { CreateBoardStageDto } from './dto/create-board-stage.dto';
import { CreateStageDto } from './dto/create-stage.dto';
import { RenameStageDto } from './dto/rename-stage.dto';
import { ReorderStagesDto } from './dto/reorder-stages.dto';

type PrismaBoard = {
  id: string;
  projectId: string;
  mode: string;
  name: string;
  createdAt: Date;
  updatedAt: Date;
  stages: PrismaStage[];
};

type PrismaStage = {
  id: string;
  boardId: string;
  name: string;
  orderIndex: number;
  kind: string;
  createdAt: Date;
  updatedAt: Date;
};

const DEFAULT_STAGES: CreateBoardStageDto[] = [
  { name: 'To Do', kind: 'regular' },
  { name: 'Done', kind: 'terminalSuccess' },
  { name: 'Cancelled', kind: 'terminalFailure' },
];

@Injectable()
export class BoardsService {
  constructor(private readonly prisma: PrismaService) {}

  async findByProject(userId: string, projectId: string): Promise<BoardDto[]> {
    await this.requireProjectOwnership(userId, projectId);

    const boards = await this.prisma.board.findMany({
      where: { projectId },
      include: { stages: { orderBy: { orderIndex: 'asc' } } },
      orderBy: { createdAt: 'asc' },
    });

    return boards.map(BoardsService.toDto);
  }

  async create(
    userId: string,
    projectId: string,
    dto: CreateBoardDto,
  ): Promise<BoardDto> {
    const project = await this.requireProjectOwnership(userId, projectId);

    const stages = dto.stages ?? DEFAULT_STAGES;
    this.validateStageSet(stages);

    const board = await this.prisma.board.create({
      data: {
        workspaceId: project.workspaceId,
        projectId,
        mode: project.mode,
        name: dto.name,
        stages: {
          create: stages.map((s, i) => ({
            name: s.name,
            kind: s.kind,
            orderIndex: i,
          })),
        },
      },
      include: { stages: { orderBy: { orderIndex: 'asc' } } },
    });

    return BoardsService.toDto(board);
  }

  async createStage(
    userId: string,
    boardId: string,
    dto: CreateStageDto,
  ): Promise<BoardStageDto> {
    const board = await this.requireBoardOwnership(userId, boardId);

    const maxOrder = board.stages.reduce(
      (max, s) => Math.max(max, s.orderIndex),
      -1,
    );

    const stage = await this.prisma.boardStage.create({
      data: {
        boardId,
        name: dto.name,
        kind: 'regular',
        orderIndex: maxOrder + 1,
      },
    });

    return BoardsService.toStageDto(stage);
  }

  async renameStage(
    userId: string,
    boardId: string,
    stageId: string,
    dto: RenameStageDto,
  ): Promise<BoardStageDto> {
    await this.requireBoardOwnership(userId, boardId);
    const stage = await this.requireStageInBoard(stageId, boardId);

    const updated = await this.prisma.boardStage.update({
      where: { id: stage.id },
      data: { name: dto.name },
    });

    return BoardsService.toStageDto(updated);
  }

  async reorderStages(
    userId: string,
    boardId: string,
    dto: ReorderStagesDto,
  ): Promise<BoardStageDto[]> {
    const board = await this.requireBoardOwnership(userId, boardId);

    const boardStageIds = new Set(board.stages.map((s) => s.id));
    if (
      dto.stageIds.length !== boardStageIds.size ||
      !dto.stageIds.every((id) => boardStageIds.has(id))
    ) {
      throw new BadRequestException(
        'stageIds must contain exactly all stage IDs of this board',
      );
    }

    await this.prisma.$transaction(
      dto.stageIds.map((id, index) =>
        this.prisma.boardStage.update({
          where: { id },
          data: { orderIndex: index },
        }),
      ),
    );

    const stages = await this.prisma.boardStage.findMany({
      where: { boardId },
      orderBy: { orderIndex: 'asc' },
    });

    return stages.map(BoardsService.toStageDto);
  }

  async deleteStage(
    userId: string,
    boardId: string,
    stageId: string,
  ): Promise<void> {
    const board = await this.requireBoardOwnership(userId, boardId);
    const stage = await this.requireStageInBoard(stageId, boardId);

    if (stage.kind !== 'regular') {
      throw new BadRequestException('Terminal stages cannot be deleted');
    }

    const remainingAfterDelete = board.stages.filter((s) => s.id !== stageId);
    const regularCount = remainingAfterDelete.filter(
      (s) => s.kind === 'regular',
    ).length;

    if (remainingAfterDelete.length < 3 || regularCount < 1) {
      throw new BadRequestException(
        'Board must retain at least 3 stages with at least one regular stage',
      );
    }

    const fallbackStage = remainingAfterDelete
      .sort((a, b) => a.orderIndex - b.orderIndex)
      .find((s) => s.kind === 'regular');

    await this.prisma.$transaction([
      this.prisma.task.updateMany({
        where: { stageId },
        data: { stageId: fallbackStage!.id },
      }),
      this.prisma.boardStage.delete({ where: { id: stageId } }),
    ]);
  }

  // --- ownership helpers ---

  private async requireProjectOwnership(userId: string, projectId: string) {
    const project = await this.prisma.project.findFirst({
      where: { id: projectId, workspace: { userId } },
    });
    if (!project) throw new NotFoundException('Project not found');
    return project;
  }

  private async requireBoardOwnership(userId: string, boardId: string) {
    const board = await this.prisma.board.findFirst({
      where: { id: boardId, workspace: { userId } },
      include: { stages: { orderBy: { orderIndex: 'asc' } } },
    });
    if (!board) throw new NotFoundException('Board not found');
    return board;
  }

  private async requireStageInBoard(stageId: string, boardId: string) {
    const stage = await this.prisma.boardStage.findFirst({
      where: { id: stageId, boardId },
    });
    if (!stage) throw new NotFoundException('Stage not found');
    return stage;
  }

  // --- invariant validation ---

  private validateStageSet(stages: CreateBoardStageDto[]): void {
    if (stages.length < 3) {
      throw new BadRequestException('A board must have at least 3 stages');
    }

    const successCount = stages.filter(
      (s) => s.kind === 'terminalSuccess',
    ).length;
    const failureCount = stages.filter(
      (s) => s.kind === 'terminalFailure',
    ).length;
    const regularCount = stages.filter((s) => s.kind === 'regular').length;

    if (successCount !== 1) {
      throw new BadRequestException(
        'A board must have exactly one terminalSuccess stage',
      );
    }
    if (failureCount !== 1) {
      throw new BadRequestException(
        'A board must have exactly one terminalFailure stage',
      );
    }
    if (regularCount < 1) {
      throw new BadRequestException(
        'A board must have at least one regular stage',
      );
    }
  }

  // --- mappers ---

  private static toDto(board: PrismaBoard): BoardDto {
    return {
      boardId: board.id,
      projectId: board.projectId,
      mode: board.mode as 'online',
      name: board.name,
      stages: board.stages.map(BoardsService.toStageDto),
      createdAt: board.createdAt.toISOString(),
      updatedAt: board.updatedAt.toISOString(),
    };
  }

  private static toStageDto(stage: PrismaStage): BoardStageDto {
    return {
      stageId: stage.id,
      boardId: stage.boardId,
      name: stage.name,
      orderIndex: stage.orderIndex,
      kind: stage.kind as 'regular' | 'terminalSuccess' | 'terminalFailure',
      createdAt: stage.createdAt.toISOString(),
      updatedAt: stage.updatedAt.toISOString(),
    };
  }
}
