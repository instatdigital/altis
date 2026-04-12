import { Injectable, UnauthorizedException, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../../prisma/prisma.service';

const SESSION_TTL_MS = 30 * 24 * 60 * 60 * 1000; // 30 days

interface AppleTokenClaims {
  sub: string;
  email?: string;
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  /** Verify Apple identity token and return claims.
   *  MVP: parses the JWT payload without signature verification.
   *  Production: verify against Apple's public keys. */
  private verifyAppleToken(identityToken: string): AppleTokenClaims {
    try {
      const [, payloadB64] = identityToken.split('.');
      const json = Buffer.from(payloadB64, 'base64url').toString('utf8');
      const claims = JSON.parse(json) as AppleTokenClaims;

      if (!claims.sub) {
        throw new Error('Missing sub claim');
      }
      return claims;
    } catch {
      throw new UnauthorizedException('Invalid Apple identity token');
    }
  }

  async exchange(identityToken: string): Promise<string> {
    const claims = this.verifyAppleToken(identityToken);
    const appleId = claims.sub;

    const user = await this.prisma.user.upsert({
      where: { appleId },
      update: {},
      create: {
        appleId,
        email: claims.email ?? null,
        workspaces: {
          create: {
            name: 'Personal Workspace',
          },
        },
      },
    });

    const expiresAt = new Date(Date.now() + SESSION_TTL_MS);
    const session = await this.prisma.session.create({
      data: { userId: user.id, expiresAt },
    });

    this.logger.log(`Session created: ${session.id} for user ${user.id}`);

    return this.jwt.sign({ sessionId: session.id, userId: user.id });
  }

  async revokeSession(sessionId: string): Promise<void> {
    await this.prisma.session.update({
      where: { id: sessionId },
      data: { revokedAt: new Date() },
    });
  }

  async getSessionUser(userId: string) {
    return this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
  }
}
