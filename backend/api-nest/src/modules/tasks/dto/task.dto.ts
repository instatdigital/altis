import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class TaskDto {
  @ApiProperty()
  taskId!: string;

  @ApiProperty()
  projectId!: string;

  @ApiPropertyOptional()
  boardId?: string;

  @ApiPropertyOptional()
  stageId?: string;

  @ApiProperty()
  title!: string;

  @ApiProperty({ enum: ['active', 'completed', 'failed'] })
  status!: 'active' | 'completed' | 'failed';

  @ApiProperty()
  createdAt!: string;

  @ApiProperty()
  updatedAt!: string;
}
