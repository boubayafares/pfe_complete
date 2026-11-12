export interface RegisterCoachDto {
  firstName: string;
  lastName: string;
  phone: string;
  email: string;
  password: string;
}

export interface LoginDto {
  email: string;
  password: string;
}

export interface RequestPlayerOtpDto {
  phone: string;
  channel?: 'SMS' | 'WHATSAPP';
}

export type RequestAdjointOtpDto = RequestPlayerOtpDto;

export interface VerifyPlayerOtpDto {
  phone: string;
  code: string;
}

export interface RequestCoachOtpDto {
  email: string;
  channel?: 'SMS' | 'WHATSAPP';
}

export interface VerifyCoachOtpDto {
  email: string;
  code: string;
}

export interface RefreshDto {
  refreshToken: string;
}

export interface SetAdjointPasswordDto {
  userId: number;
  password: string;
}

export interface ActivateAdjointByPhoneDto {
  phone: string;
  code: string;
  password: string;
}
