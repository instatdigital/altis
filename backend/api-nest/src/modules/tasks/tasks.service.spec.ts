import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException, BadRequestException } from '@nestjs/common';
import { TasksService } from './tasks.service';
import { PrismaService } from '../../prisma/prisma.service';

const makeStage = (id: string, kind: string) => ({
  id,
  boardId: 'board-uuid',
  name: kind,
  kind,
  orderIndex: 0,
  createdAt: new Date(),
  updatedAt: new Date(),
});

const mockProject = {
  id: 'proj-uuid',
  workspaceId: 'ws-uuid',
  mode: 'online',
  name: 'P',
  createdAt: new Date(),
  updatedAt: new Date(),
};

const mockBoard = {
  id: 'board-uuid',
  workspaceId: 'ws-uuid',
  projectId: 'proj-uuid',
  mode: 'online',
  name: 'B',
  createdAt: new Date(),
  updatedAt: new Date(),
  stages: [
    { ...makeStage('stage-todo', 'regular'), orderIndex: 0 },
    { ...makeStage('stage-done', 'terminalSuccess'), orderIndex: 1 },
    { ...makeStage('stage-fail', 'terminalFailure'), orderIndex: 2 },
  ],
};

const mockTask = {
  id: 'task-uuid',
  workspaceId: 'ws-uuid',
  projectId: 'proj-uuid',
  boardId: 'board-uuid',
  stageId: 'stage-todo',
  title: 'My Task',
  status: 'active',
  createdAt: new Date(),
  updatedAt: new Date(),
};

describe('TasksService', () => {
  let service: TasksService;
  let prisma: jest.Mocked<PrismaService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TasksService,
        {
          provide: PrismaService,
          useValue: {
            project: { findFirst: jest.fn() },
            board: { findFirst: jest.fn() },
            task: {
              create: jest.fn(),
              update: jest.fn(),
              findFirst: jest.fn(),
            },
            boardStage: { findFirst: jest.fn() },
          },
        },
      ],
    }).compile();

    service = module.get(TasksService);
    prisma = module.get(PrismaService) as jest.Mocked<PrismaService>;
  });

  describe('createForProject', () => {
    it('creates a task scoped to project', async () => {
      (prisma.project.findFirst as jest.Mock).mockResolvedValue(mockProject);
      (prisma.task.create as jest.Mock).mockResolvedValue(mockTask);

      const result = await service.createForProject('user-uuid', 'proj-uuid', {
        title: 'My Task',
      });

      expect(result.taskId).toBe('task-uuid');
      expect(result.projectId).toBe('proj-uuid');
    });

    it('throws NotFoundException when project not owned', async () => {
      (prisma.project.findFirst as jest.Mock).mockResolvedValue(null);

      await expect(
        service.createForProject('user-uuid', 'proj-uuid', { title: 'X' }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('createForBoard', () => {
    it('creates task placed on first regular stage', async () => {
      (prisma.board.findFirst as jest.Mock).mockResolvedValue(mockBoard);
      (prisma.task.create as jest.Mock).mockResolvedValue(mockTask);

      const result = await service.createForBoard('user-uuid', 'board-uuid', {
        title: 'My Task',
      });

      expect(result.taskId).toBe('task-uuid');
    });

    it('throws BadRequestException for stageId not on this board', async () => {
      (prisma.board.findFirst as jest.Mock).mockResolvedValue(mockBoard);

      await expect(
        service.createForBoard('user-uuid', 'board-uuid', {
          title: 'X',
          stageId: 'other-stage',
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('move', () => {
    it('moves task to new stage and updates status', async () => {
      (prisma.task.findFirst as jest.Mock).mockResolvedValue(mockTask);
      (prisma.boardStage.findFirst as jest.Mock).mockResolvedValue(
        makeStage('stage-done', 'terminalSuccess'),
      );
      (prisma.task.update as jest.Mock).mockResolvedValue({
        ...mockTask,
        stageId: 'stage-done',
        status: 'completed',
      });

      const result = await service.move('user-uuid', 'task-uuid', {
        stageId: 'stage-done',
      });

      expect(result.status).toBe('completed');
    });

    it('throws BadRequestException when task has no board', async () => {
      (prisma.task.findFirst as jest.Mock).mockResolvedValue({
        ...mockTask,
        boardId: null,
      });

      await expect(
        service.move('user-uuid', 'task-uuid', { stageId: 'stage-done' }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('complete', () => {
    it('marks task as completed and moves to terminalSuccess stage', async () => {
      (prisma.task.findFirst as jest.Mock).mockResolvedValue(mockTask);
      (prisma.boardStage.findFirst as jest.Mock).mockResolvedValue(
        makeStage('stage-done', 'terminalSuccess'),
      );
      (prisma.task.update as jest.Mock).mockResolvedValue({
        ...mockTask,
        status: 'completed',
        stageId: 'stage-done',
      });

      const result = await service.complete('user-uuid', 'task-uuid');

      expect(result.status).toBe('completed');
    });
  });

  describe('fail', () => {
    it('marks task as failed and moves to terminalFailure stage', async () => {
      (prisma.task.findFirst as jest.Mock).mockResolvedValue(mockTask);
      (prisma.boardStage.findFirst as jest.Mock).mockResolvedValue(
        makeStage('stage-fail', 'terminalFailure'),
      );
      (prisma.task.update as jest.Mock).mockResolvedValue({
        ...mockTask,
        status: 'failed',
        stageId: 'stage-fail',
      });

      const result = await service.fail('user-uuid', 'task-uuid');

      expect(result.status).toBe('failed');
    });
  });
});
