import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { ProjectsService } from './projects.service';
import { PrismaService } from '../../prisma/prisma.service';

const mockWorkspace = {
  id: 'ws-uuid',
  userId: 'user-uuid',
  name: 'Personal Workspace',
  createdAt: new Date('2024-01-01'),
  updatedAt: new Date('2024-01-01'),
};

const mockProject = {
  id: 'proj-uuid',
  workspaceId: 'ws-uuid',
  mode: 'online',
  name: 'Test Project',
  createdAt: new Date('2024-01-01'),
  updatedAt: new Date('2024-01-01'),
};

describe('ProjectsService', () => {
  let service: ProjectsService;
  let prisma: jest.Mocked<PrismaService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProjectsService,
        {
          provide: PrismaService,
          useValue: {
            project: {
              findMany: jest.fn(),
              create: jest.fn(),
            },
            workspace: {
              findFirst: jest.fn(),
            },
          },
        },
      ],
    }).compile();

    service = module.get(ProjectsService);
    prisma = module.get(PrismaService) as jest.Mocked<PrismaService>;
  });

  describe('findAll', () => {
    it('returns mapped ProjectDtos for user', async () => {
      (prisma.project.findMany as jest.Mock).mockResolvedValue([mockProject]);

      const result = await service.findAll('user-uuid');

      expect(result).toHaveLength(1);
      expect(result[0]).toMatchObject({
        projectId: 'proj-uuid',
        mode: 'online',
        name: 'Test Project',
      });
    });

    it('returns empty array when user has no projects', async () => {
      (prisma.project.findMany as jest.Mock).mockResolvedValue([]);

      const result = await service.findAll('user-uuid');

      expect(result).toEqual([]);
    });
  });

  describe('create', () => {
    it('creates a project in the user workspace', async () => {
      (prisma.workspace.findFirst as jest.Mock).mockResolvedValue(
        mockWorkspace,
      );
      (prisma.project.create as jest.Mock).mockResolvedValue(mockProject);

      const result = await service.create('user-uuid', {
        name: 'Test Project',
      });

      expect(prisma.project.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            mode: 'online',
            name: 'Test Project',
          }),
        }),
      );
      expect(result.projectId).toBe('proj-uuid');
    });

    it('throws NotFoundException when workspace not found', async () => {
      (prisma.workspace.findFirst as jest.Mock).mockResolvedValue(null);

      await expect(service.create('user-uuid', { name: 'X' })).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
