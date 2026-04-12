import { ApiProperty } from '@nestjs/swagger';

export class BoardStageDto {
  @ApiProperty()
  stageId!: string;

  @ApiProperty()
  boardId!: string;

  @ApiProperty()
  name!: string;

  @ApiProperty()
  orderIndex!: number;

  @ApiProperty({ enum: ['regular', 'terminalSuccess', 'terminalFailure'] })
  kind!: 'regular' | 'terminalSuccess' | 'terminalFailure';

  @ApiProperty()
  createdAt!: string;

  @ApiProperty()
  updatedAt!: string;
}
