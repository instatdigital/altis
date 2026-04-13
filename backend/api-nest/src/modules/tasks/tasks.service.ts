import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { TaskDto } from './dto/task.dto';
import { CreateTaskDto } from './dto/create-task.dto';
import { UpdateTaskDto } from './dto/update-task.dto';
import { MoveTaskDto } from './dto/move-task.dto';

type PrismaTask = {
  id: string;
  projectId: string;
  boardId: string | null;
  stageId: string | null;
  title: string;
  status: string;
  createdAt: Date;
  updatedAt: Date;
};

@Injectable()
export class TasksService {
  constructor(private readonly prisma: PrismaService) {}

  async createForProject(
    userId: string,
    projectId: string,
    dto: CreateTaskDto,
  ): Promise<TaskDto> {
    const project = await this.requireProjectOwnership(userId, projectId);

    const task = await this.prisma.task.create({
      data: {
        workspaceId: project.workspaceId,
        projectId,
        title: dto.title,
        status: 'active',
      },
    });

    return TasksService.toDto(task);
  }

  async createForBoard(
    userId: string,
    boardId: string,
    dto: CreateTaskDto,
  ): Promise<TaskDto> {
    const board = await this.requireBoardOwnership(userId, boardId);

    let stageId: string;
    let expectedStatus = 'active';

    if (dto.stageId) {
      const stage = board.stages.find((s) => s.id === dto.stageId);
      if (!stage) {
        throw new BadRequestException('Stage does not belong to this board');
      }
      stageId = stage.id;
      if (stage.kind === 'terminalSuccess') expectedStatus = 'completed';
      if (stage.kind === 'terminalFailure') expectedStatus = 'failed';
    } else {
      const firstRegular = board.stages
        .sort((a, b) => a.orderIndex - b.orderIndex)
        .find((s) => s.kind === 'regular');
      if (!firstRegular) {
        throw new BadRequestException('Board has no regular stage');
      }
      stageId = firstRegular.id;
    }

    const task = await this.prisma.task.create({
      data: {
        workspaceId: board.workspaceId,
        projectId: board.projectId,
        boardId,
        stageId,
        title: dto.title,
        status: expectedStatus,
      },
    });

    return TasksService.toDto(task);
  }

  async update(
    userId: string,
    taskId: string,
    dto: UpdateTaskDto,
  ): Promise<TaskDto> {
    const task = await this.requireTaskOwnership(userId, taskId);

    const updated = await this.prisma.task.update({
      where: { id: task.id },
      data: { ...(dto.title !== undefined && { title: dto.title }) },
    });

    return TasksService.toDto(updated);
  }

  async move(
    userId: string,
    taskId: string,
    dto: MoveTaskDto,
  ): Promise<TaskDto> {
    const task = await this.requireTaskOwnership(userId, taskId);

    if (!task.boardId) {
      throw new BadRequestException(
        'Only board-scoped tasks can be moved between stages',
      );
    }

    const stage = await this.prisma.boardStage.findFirst({
      where: { id: dto.stageId, boardId: task.boardId },
    });
    if (!stage) {
      throw new BadRequestException(
        "Stage does not belong to this task's board",
      );
    }

    let status = task.status;
    if (stage.kind === 'terminalSuccess') status = 'completed';
    else if (stage.kind === 'terminalFailure') status = 'failed';
    else if (stage.kind === 'regular') status = 'active';

    const updated = await this.prisma.task.update({
      where: { id: task.id },
      data: { stageId: dto.stageId, status },
    });

    return TasksService.toDto(updated);
  }

  async complete(userId: string, taskId: string): Promise<TaskDto> {
    const task = await this.requireTaskOwnership(userId, taskId);

    const data: { status: string; stageId?: string } = { status: 'completed' };

    if (task.boardId) {
      const stage = await this.prisma.boardStage.findFirst({
        where: { boardId: task.boardId, kind: 'terminalSuccess' },
      });
      if (!stage)
        throw new BadRequestException('Board has no terminalSuccess stage');
      data.stageId = stage.id;
    }

    const updated = await this.prisma.task.update({
      where: { id: task.id },
      data,
    });

    return TasksService.toDto(updated);
  }

  async fail(userId: string, taskId: string): Promise<TaskDto> {
    const task = await this.requireTaskOwnership(userId, taskId);

    const data: { status: string; stageId?: string } = { status: 'failed' };

    if (task.boardId) {
      const stage = await this.prisma.boardStage.findFirst({
        where: { boardId: task.boardId, kind: 'terminalFailure' },
      });
      if (!stage)
        throw new BadRequestException('Board has no terminalFailure stage');
      data.stageId = stage.id;
    }

    const updated = await this.prisma.task.update({
      where: { id: task.id },
      data,
    });

    return TasksService.toDto(updated);
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

  private async requireTaskOwnership(userId: string, taskId: string) {
    const task = await this.prisma.task.findFirst({
      where: { id: taskId, workspace: { userId } },
    });
    if (!task) throw new NotFoundException('Task not found');
    return task;
  }

  // --- mapper ---

  private static toDto(task: PrismaTask): TaskDto {
    return {
      taskId: task.id,
      projectId: task.projectId,
      ...(task.boardId !== null && { boardId: task.boardId }),
      ...(task.stageId !== null && { stageId: task.stageId }),
      title: task.title,
      status: task.status as 'active' | 'completed' | 'failed',
      createdAt: task.createdAt.toISOString(),
      updatedAt: task.updatedAt.toISOString(),
    };
  }
}
