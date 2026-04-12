import {
  IsString,
  MinLength,
  MaxLength,
  IsOptional,
  IsArray,
  ValidateNested,
  ArrayMinSize,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { CreateBoardStageDto } from './create-board-stage.dto';

export class CreateBoardDto {
  @ApiProperty({ description: 'Board name', minLength: 1, maxLength: 100 })
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  name!: string;

  @ApiPropertyOptional({
    description:
      'Initial stages. If omitted, defaults to [Todo, Done, Cancelled]. Must include exactly one terminalSuccess and one terminalFailure, and at least one regular.',
    type: [CreateBoardStageDto],
  })
  @IsOptional()
  @IsArray()
  @ArrayMinSize(3)
  @ValidateNested({ each: true })
  @Type(() => CreateBoardStageDto)
  stages?: CreateBoardStageDto[];
}
