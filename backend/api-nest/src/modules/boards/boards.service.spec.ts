import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException, BadRequestException } from '@nestjs/common';
import { BoardsService } from './boards.service';
import { PrismaService } from '../../prisma/prisma.service';

const mockProject = {
  id: 'proj-uuid',
  workspaceId: 'ws-uuid',
  mode: 'online',
  name: 'Test Project',
  createdAt: new Date(),
  updatedAt: new Date(),
};

const makeStage = (id: string, kind: string, orderIndex: number) => ({
  id,
  boardId: 'board-uuid',
  name: kind,
  kind,
  orderIndex,
  createdAt: new Date(),
  updatedAt: new Date(),
});

const mockBoard = {
  id: 'board-uuid',
  workspaceId: 'ws-uuid',
  projectId: 'proj-uuid',
  mode: 'online',
  name: 'Test Board',
  createdAt: new Date(),
  updatedAt: new Date(),
  stages: [
    makeStage('stage-todo', 'regular', 0),
    makeStage('stage-done', 'terminalSuccess', 1),
    makeStage('stage-cancelled', 'terminalFailure', 2),
  ],
};

describe('BoardsService', () => {
  let service: BoardsService;
  let prisma: jest.Mocked<PrismaService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BoardsService,
        {
          provide: PrismaService,
          useValue: {
            project: { findFirst: jest.fn() },
            board: {
              findMany: jest.fn(),
              create: jest.fn(),
              findFirst: jest.fn(),
            },
            boardStage: {
              create: jest.fn(),
              update: jest.fn(),
              findMany: jest.fn(),
              findFirst: jest.fn(),
              delete: jest.fn(),
            },
            task: { updateMany: jest.fn() },
            $transaction: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get(BoardsService);
    prisma = module.get(PrismaService) as jest.Mocked<PrismaService>;
  });

  describe('findByProject', () => {
    it('returns boards for an owned project', async () => {
      (prisma.project.findFirst as jest.Mock).mockResolvedValue(mockProject);
      (prisma.board.findMany as jest.Mock).mockResolvedValue([mockBoard]);

      const result = await service.findByProject('user-uuid', 'proj-uuid');

      expect(result).toHaveLength(1);
      expect(result[0].boardId).toBe('board-uuid');
      expect(result[0].stages).toHaveLength(3);
    });

    it('throws NotFoundException when project not owned', async () => {
      (prisma.project.findFirst as jest.Mock).mockResolvedValue(null);

      await expect(
        service.findByProject('user-uuid', 'proj-uuid'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('create', () => {
    it('creates board with default stages', async () => {
      (prisma.project.findFirst as jest.Mock).mockResolvedValue(mockProject);
      (prisma.board.create as jest.Mock).mockResolvedValue(mockBoard);

      const result = await service.create('user-uuid', 'proj-uuid', {
        name: 'Sprint 1',
      });

      expect(prisma.board.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ mode: 'online', name: 'Sprint 1' }),
        }),
      );
      expect(result.boardId).toBe('board-uuid');
    });

    it('rejects stage set missing terminalSuccess', async () => {
      (prisma.project.findFirst as jest.Mock).mockResolvedValue(mockProject);

      await expect(
        service.create('user-uuid', 'proj-uuid', {
          name: 'X',
          stages: [
            { name: 'A', kind: 'regular' },
            { name: 'B', kind: 'regular' },
            { name: 'C', kind: 'terminalFailure' },
          ],
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects stage set with fewer than 3 stages', async () => {
      (prisma.project.findFirst as jest.Mock).mockResolvedValue(mockProject);

      await expect(
        service.create('user-uuid', 'proj-uuid', {
          name: 'X',
          stages: [
            { name: 'A', kind: 'terminalSuccess' },
            { name: 'B', kind: 'terminalFailure' },
          ],
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('deleteStage', () => {
    it('throws BadRequestException when deleting a terminal stage', async () => {
      (prisma.board.findFirst as jest.Mock).mockResolvedValue(mockBoard);
      (prisma.boardStage.findFirst as jest.Mock).mockResolvedValue(
        makeStage('stage-done', 'terminalSuccess', 1),
      );

      await expect(
        service.deleteStage('user-uuid', 'board-uuid', 'stage-done'),
      ).rejects.toThrow(BadRequestException);
    });
  });
});
