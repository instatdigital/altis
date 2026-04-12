import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateProjectDto } from './dto/create-project.dto';
import { ProjectDto } from './dto/project.dto';

@Injectable()
export class ProjectsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(userId: string): Promise<ProjectDto[]> {
    const projects = await this.prisma.project.findMany({
      where: {
        mode: 'online',
        workspace: { userId },
      },
      orderBy: { createdAt: 'desc' },
    });

    return projects.map(this.toDto);
  }

  async create(userId: string, dto: CreateProjectDto): Promise<ProjectDto> {
    const workspace = await this.prisma.workspace.findFirst({
      where: { userId },
      orderBy: { createdAt: 'asc' },
    });

    if (!workspace) {
      throw new NotFoundException('Workspace not found for user');
    }

    const project = await this.prisma.project.create({
      data: {
        workspaceId: workspace.id,
        mode: 'online',
        name: dto.name,
      },
    });

    return this.toDto(project);
  }

  private toDto(project: {
    id: string;
    mode: string;
    name: string;
    createdAt: Date;
    updatedAt: Date;
  }): ProjectDto {
    return {
      projectId: project.id,
      mode: 'online',
      name: project.name,
      createdAt: project.createdAt.toISOString(),
      updatedAt: project.updatedAt.toISOString(),
    };
  }
}
