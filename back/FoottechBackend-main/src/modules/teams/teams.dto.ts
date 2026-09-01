export interface CreateTeamDto {
  name: string;
  category?: string;
  logo?: string;
  description?: string;
}

export interface UpdateTeamDto extends Partial<CreateTeamDto> {}

export interface AddAdjointDto {
  firstName: string;
  lastName: string;
  phone: string;
  email: string;
}
