import { ApiProperty } from '@nestjs/swagger';
import { IsUUID } from 'class-validator';

export class MoveTaskDto {
  @ApiProperty({
    description: 'Target stage ID (must belong to the same board)',
  })
  @IsUUID()
  stageId!: string;
}
