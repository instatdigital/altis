import { ApiProperty } from '@nestjs/swagger';

export class ProfileDto {
  @ApiProperty()
  userId!: string;

  @ApiProperty({ nullable: true })
  email!: string | null;

  @ApiProperty({ nullable: true })
  name!: string | null;

  @ApiProperty()
  createdAt!: string;

  @ApiProperty()
  updatedAt!: string;
}
