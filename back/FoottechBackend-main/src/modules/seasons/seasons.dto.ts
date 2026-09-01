export interface CreateSeasonDto {
  name: string;
  startDate: string;
  endDate: string;
  isCurrent?: boolean;
}

export interface UpdateSeasonDto extends Partial<CreateSeasonDto> {}
