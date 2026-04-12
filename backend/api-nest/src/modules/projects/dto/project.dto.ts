import { ApiProperty } from '@nestjs/swagger';

export class ProjectDto {
  @ApiProperty()
  projectId!: string;

  @ApiProperty({ enum: ['online'] })
  mode!: 'online';

  @ApiProperty()
  name!: string;

  @ApiProperty()
  createdAt!: string;

  @ApiProperty()
  updatedAt!: string;
}
