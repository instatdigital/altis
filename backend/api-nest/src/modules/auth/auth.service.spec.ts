import { Test, TestingModule } from '@nestjs/testing';
import { UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AuthService } from './auth.service';
import { PrismaService } from '../../prisma/prisma.service';

const mockUser = {
  id: 'user-uuid',
  appleId: 'apple.sub.123',
  email: 'test@example.com',
  name: null,
  createdAt: new Date(),
  updatedAt: new Date(),
};

const mockSession = {
  id: 'session-uuid',
  userId: 'user-uuid',
  expiresAt: new Date(Date.now() + 86400000),
  revokedAt: null,
  createdAt: new Date(),
};

describe('AuthService', () => {
  let service: AuthService;
  let prisma: jest.Mocked<PrismaService>;
  let jwt: jest.Mocked<JwtService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        {
          provide: PrismaService,
          useValue: {
            user: { upsert: jest.fn() },
            session: {
              create: jest.fn(),
              update: jest.fn(),
              findUnique: jest.fn(),
            },
          },
        },
        {
          provide: JwtService,
          useValue: { sign: jest.fn(), verify: jest.fn() },
        },
      ],
    }).compile();

    service = module.get(AuthService);
    prisma = module.get(PrismaService) as jest.Mocked<PrismaService>;
    jwt = module.get(JwtService) as jest.Mocked<JwtService>;
  });

  describe('exchange', () => {
    it('upserts user and creates session, returns signed token', async () => {
      const payload = { sub: 'apple.sub.123', email: 'test@example.com' };
      const encodedPayload = Buffer.from(JSON.stringify(payload)).toString(
        'base64url',
      );
      const identityToken = `header.${encodedPayload}.sig`;

      (prisma.user.upsert as jest.Mock).mockResolvedValue(mockUser);
      (prisma.session.create as jest.Mock).mockResolvedValue(mockSession);
      (jwt.sign as jest.Mock).mockReturnValue('signed-token');

      const token = await service.exchange(identityToken);

      expect(prisma.user.upsert).toHaveBeenCalledWith(
        expect.objectContaining({ where: { appleId: 'apple.sub.123' } }),
      );
      expect(prisma.session.create).toHaveBeenCalled();
      expect(token).toBe('signed-token');
    });

    it('throws UnauthorizedException for malformed identity token', async () => {
      await expect(service.exchange('not.valid')).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('throws UnauthorizedException when sub claim is missing', async () => {
      const payload = { email: 'test@example.com' };
      const encodedPayload = Buffer.from(JSON.stringify(payload)).toString(
        'base64url',
      );
      const identityToken = `header.${encodedPayload}.sig`;

      await expect(service.exchange(identityToken)).rejects.toThrow(
        UnauthorizedException,
      );
    });
  });

  describe('revokeSession', () => {
    it('updates session with revokedAt', async () => {
      (prisma.session.update as jest.Mock).mockResolvedValue({});

      await service.revokeSession('session-uuid');

      expect(prisma.session.update).toHaveBeenCalledWith({
        where: { id: 'session-uuid' },
        data: expect.objectContaining({ revokedAt: expect.any(Date) }),
      });
    });
  });

  describe('getSessionUser', () => {
    it('returns user by id', async () => {
      (prisma.user as any).findUniqueOrThrow = jest
        .fn()
        .mockResolvedValue(mockUser);

      const user = await service.getSessionUser('user-uuid');

      expect(user).toBe(mockUser);
    });
  });
});
