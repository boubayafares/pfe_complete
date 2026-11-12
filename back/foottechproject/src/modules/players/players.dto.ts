export interface CreatePlayerDto {
  firstName: string;
  lastName: string;
  phone: string;
  dateNaissance?: string;
  posteP?: string;
  posteS?: string;
  piedFort?: 'DROIT' | 'GAUCHE' | 'AMBIDEXTRE';
  numeroMaillot?: number;
}

export interface UpdatePlayerDto {
  dateNaissance?: string;
  tailleCm?: number;
  poidsKg?: number;
  posteP?: string;
  posteS?: string;
  piedFort?: 'DROIT' | 'GAUCHE' | 'AMBIDEXTRE';
  numeroMaillot?: number;
}

export interface UpsertGuardianDto {
  relation: 'PERE' | 'MERE' | 'TUTEUR';
  nom?: string;
  prenom?: string;
  dateNaissance?: string;
  tel1?: string;
  tel2?: string;
  email?: string;
}

export interface UpsertAddressDto {
  adresseComplete?: string;
  distanceClubKm?: number;
  moyenTransport?: string;
  dureeTrajetMin?: number;
}

export interface UpsertSchoolInfoDto {
  etablissement?: string;
  distanceClubKm?: number;
  classe?: string;
  niveauScolaire?: 'FAIBLE' | 'MOYEN' | 'BIEN' | 'TRES_BIEN';
}

export interface UpsertSeasonProfileDto {
  season: string;
  clubNiveau?: string;
  poidsKg?: number;
  tailleCm?: number;
  pointure?: number;
  tailleVetement?: string;
  poste1?: string;
  poste2?: string;
  pointsForts?: string;
  pointsAAmeliorer?: string;
}

export interface CreateInjuryDto {
  dateBlessure: string;
  description?: string;
  dureeIndisponibiliteJours?: number;
}

export interface UpdateInjuryDto {
  dateRetour?: string;
  description?: string;
  dureeIndisponibiliteJours?: number;
}
