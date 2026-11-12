export interface PlayerRecord {
  id: number;
  team_id: number | null;
  date_naissance: Date | null;
  taille_cm: number | null;
  poids_kg: number | null;
  poste_principal: string | null;
  poste_secondaire: string | null;
  pied_fort: 'DROIT' | 'GAUCHE' | 'AMBIDEXTRE' | null;
  numero_maillot: number | null;
}

export interface PlayerProfile extends PlayerRecord {
  first_name: string;
  last_name: string;
  phone: string;
  profile_image: string | null;
  account_status: string;
}

export interface GuardianRecord {
  id: number;
  player_id: number;
  relation: 'PERE' | 'MERE' | 'TUTEUR';
  nom: string | null;
  prenom: string | null;
  date_naissance: Date | null;
  tel1: string | null;
  tel2: string | null;
  email: string | null;
}

export interface AddressRecord {
  player_id: number;
  adresse_complete: string | null;
  distance_club_km: number | null;
  moyen_transport: string | null;
  duree_trajet_min: number | null;
}

export interface SchoolInfoRecord {
  player_id: number;
  etablissement: string | null;
  distance_club_km: number | null;
  classe: string | null;
  niveau_scolaire: 'FAIBLE' | 'MOYEN' | 'BIEN' | 'TRES_BIEN' | null;
}

export interface SeasonProfileRecord {
  id: number;
  player_id: number;
  season: string;
  club_niveau: string | null;
  poids_kg: number | null;
  taille_cm: number | null;
  pointure: number | null;
  taille_vetement: string | null;
  poste1: string | null;
  poste2: string | null;
  points_forts: string | null;
  points_a_ameliorer: string | null;
}

export interface InjuryRecord {
  id: number;
  player_id: number;
  date_blessure: Date;
  description: string | null;
  duree_indisponibilite_jours: number | null;
  date_retour: Date | null;
}
