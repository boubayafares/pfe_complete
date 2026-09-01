export interface UserRecord {
  id: number;
  first_name: string;
  last_name: string;
  phone: string;
  email: string | null;
  password_hash: string | null;
  profile_image: string | null;
  account_status: 'ACTIVE' | 'INACTIVE' | 'BLOCKED';
  created_at: Date;
  updated_at: Date;
}

export interface RoleRecord {
  id: number;
  name: 'COACH' | 'ADJOINT' | 'JOUEUR';
}

export interface RefreshTokenRecord {
  id: number;
  user_id: number;
  token_hash: string;
  expires_at: Date;
  revoked: boolean;
  created_at: Date;
}

export interface ActivationCodeRecord {
  id: number;
  user_id: number;
  code: string;
  channel: 'SMS' | 'WHATSAPP';
  expires_at: Date;
  used: boolean;
  created_at: Date;
}
