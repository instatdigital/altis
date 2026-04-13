import { Test, TestingModule } from '@nestjs/testing';
import { ProfileService } from './profile.service';
import { PrismaService } from '../../prisma/prisma.service';

const mockUser = {
  id: 'user-uuid',
  appleId: 'apple.sub.123',
  email: 'test@example.com',
  name: 'Test User',
  createdAt: new Date('2024-01-01T00:00:00Z'),
  updatedAt: new Date('2024-01-02T00:00:00Z'),
};

describe('ProfileService', () => {
  let service: ProfileService;
  let prisma: jest.Mocked<PrismaService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProfileService,
        {
          provide: PrismaService,
          useValue: {
            user: { findUniqueOrThrow: jest.fn() },
          },
        },
      ],
    }).compile();

    service = module.get(ProfileService);
    prisma = module.get(PrismaService) as jest.Mocked<PrismaService>;
  });

  describe('getMe', () => {
    it('returns profile DTO for authenticated user', async () => {
      (prisma.user.findUniqueOrThrow as jest.Mock).mockResolvedValue(mockUser);

      const result = await service.getMe('user-uuid');

      expect(result).toEqual({
        userId: 'user-uuid',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-02T00:00:00.000Z',
      });
    });

    it('returns null email and name when not set', async () => {
      (prisma.user.findUniqueOrThrow as jest.Mock).mockResolvedValue({
        ...mockUser,
        email: null,
        name: null,
      });

      const result = await service.getMe('user-uuid');

      expect(result.email).toBeNull();
      expect(result.name).toBeNull();
    });
  });
});
