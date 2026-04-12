import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty } from 'class-validator';

export class AppleExchangeDto {
  @ApiProperty({ description: 'Apple identity token from client' })
  @IsString()
  @IsNotEmpty()
  identityToken!: string;
}
