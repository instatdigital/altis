import { ApiProperty } from '@nestjs/swagger';
import { BoardStageDto } from './board-stage.dto';

export class BoardDto {
  @ApiProperty()
  boardId!: string;

  @ApiProperty()
  projectId!: string;

  @ApiProperty({ enum: ['online'] })
  mode!: 'online';

  @ApiProperty()
  name!: string;

  @ApiProperty({ type: [BoardStageDto] })
  stages!: BoardStageDto[];

  @ApiProperty()
  createdAt!: string;

  @ApiProperty()
  updatedAt!: string;
}
