import { z } from 'zod';

export const createPlayerSchema = z.object({
  firstName: z.string().min(1).max(100),
  lastName: z.string().min(1).max(100),
  phone: z.string().min(8).max(30),
  dateNaissance: z.coerce.date().optional(),
  posteP: z.string().max(10).optional(),
  posteS: z.string().max(10).optional(),
  piedFort: z.enum(['DROIT', 'GAUCHE', 'AMBIDEXTRE']).optional(),
  numeroMaillot: z.coerce.number().int().min(1).max(99).optional(),
});

export const updatePlayerSchema = z.object({
  dateNaissance: z.coerce.date().optional(),
  tailleCm: z.coerce.number().positive().optional(),
  poidsKg: z.coerce.number().positive().optional(),
  posteP: z.string().max(10).optional(),
  posteS: z.string().max(10).optional(),
  piedFort: z.enum(['DROIT', 'GAUCHE', 'AMBIDEXTRE']).optional(),
  numeroMaillot: z.coerce.number().int().min(1).max(99).optional(),
});

export const upsertGuardianSchema = z.object({
  relation: z.enum(['PERE', 'MERE', 'TUTEUR']),
  nom: z.string().max(100).optional(),
  prenom: z.string().max(100).optional(),
  dateNaissance: z.coerce.date().optional(),
  tel1: z.string().max(30).optional(),
  tel2: z.string().max(30).optional(),
  email: z.string().email().optional(),
});

export const upsertAddressSchema = z.object({
  adresseComplete: z.string().optional(),
  distanceClubKm: z.coerce.number().min(0).optional(),
  moyenTransport: z.string().max(80).optional(),
  dureeTrajetMin: z.coerce.number().int().min(0).optional(),
});

export const upsertSchoolInfoSchema = z.object({
  etablissement: z.string().max(200).optional(),
  distanceClubKm: z.coerce.number().min(0).optional(),
  classe: z.string().max(50).optional(),
  niveauScolaire: z.enum(['FAIBLE', 'MOYEN', 'BIEN', 'TRES_BIEN']).optional(),
});

export const upsertSeasonProfileSchema = z.object({
  season: z.string().min(4).max(20),
  clubNiveau: z.string().max(200).optional(),
  poidsKg: z.coerce.number().positive().optional(),
  tailleCm: z.coerce.number().positive().optional(),
  pointure: z.coerce.number().positive().optional(),
  tailleVetement: z.string().max(10).optional(),
  poste1: z.string().max(10).optional(),
  poste2: z.string().max(10).optional(),
  pointsForts: z.string().optional(),
  pointsAAmeliorer: z.string().optional(),
});

export const createInjurySchema = z.object({
  dateBlessure: z.coerce.date(),
  description: z.string().optional(),
  dureeIndisponibiliteJours: z.coerce.number().int().min(0).optional(),
});

export const updateInjurySchema = z.object({
  dateRetour: z.coerce.date().optional(),
  description: z.string().optional(),
  dureeIndisponibiliteJours: z.coerce.number().int().min(0).optional(),
});

export const playerIdParamSchema = z.object({ id: z.coerce.number().int().positive() });

export const playerInjuryParamSchema = z.object({
  id: z.coerce.number().int().positive(),
  injuryId: z.coerce.number().int().positive(),
});

export const listPlayersQuerySchema = z.object({
  page: z.coerce.number().int().positive().optional(),
  limit: z.coerce.number().int().positive().max(100).optional(),
  posteP: z.string().optional(),
  search: z.string().optional(),
});
