export interface TeamRecord {
  id: number;
  coach_id: number;
  name: string;
  category: string | null;
  logo: string | null;
  description: string | null;
  created_at: Date;
}

export interface TeamStaffRecord {
  id: number;
  team_id: number;
  adjoint_id: number;
  added_by: number | null;
  added_at: Date;
}

export interface TeamStaffWithUser extends TeamStaffRecord {
  first_name: string;
  last_name: string;
  email: string | null;
  phone: string;
  account_status: string;
}
