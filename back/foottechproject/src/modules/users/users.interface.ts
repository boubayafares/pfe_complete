export interface UserRecord {
  id: number;
  first_name: string;
  last_name: string;
  phone: string;
  email: string | null;
  profile_image: string | null;
  account_status: string;
  created_at: Date;
  updated_at: Date;
}
