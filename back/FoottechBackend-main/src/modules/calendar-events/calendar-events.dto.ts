export interface CreateCalendarEventDto {
  title: string;
  description?: string;
  startTime: string;
  endTime?: string;
  allDay?: boolean;
  location?: string;
  color?: string;
}

export interface UpdateCalendarEventDto extends Partial<CreateCalendarEventDto> {}
