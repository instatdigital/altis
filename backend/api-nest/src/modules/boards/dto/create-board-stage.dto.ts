import { IsString, IsIn, MinLength, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateBoardStageDto {
  @ApiProperty({ description: 'Stage name', minLength: 1, maxLength: 100 })
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  name!: string;

  @ApiProperty({
    enum: ['regular', 'terminalSuccess', 'terminalFailure'],
    description: 'Stage kind',
  })
  @IsString()
  @IsIn(['regular', 'terminalSuccess', 'terminalFailure'])
  kind!: 'regular' | 'terminalSuccess' | 'terminalFailure';
}
