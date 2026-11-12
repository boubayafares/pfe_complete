import { ExerciseProposalsRepository } from './exercise-proposals.repository.js';
import type { CreateProposalDto, ReviewProposalDto } from './exercise-proposals.dto.js';
import { NotFoundError, BadRequestError, ForbiddenError } from '../../shared/errors/AppError.js';

export class ExerciseProposalsService {
  private readonly repo = new ExerciseProposalsRepository();

  async list(
    teamId: number,
    filters: {
      trainingId?: number;
      status?: string;
      proposedBy?: number;
      visibility?: string;
      tag?: string;
    }
  ) {
    return this.repo.findWithFilters({ ...filters, teamId });
  }

  async getById(id: number, teamId: number) {
    const proposal = await this.repo.findById(id);
    if (!proposal) throw new NotFoundError('Exercise proposal');
    const isCommunityExercise = proposal.status === 'VALIDATED' && proposal.visibility === 'COMMUNITY';
    if (!(await this.repo.belongsToTeam(id, teamId)) && !isCommunityExercise) {
      throw new ForbiddenError('You do not have access to this proposal');
    }
    return proposal;
  }

  async library(teamId: number) {
    return this.repo.findLibrary(teamId);
  }

  async create(proposedBy: number, teamId: number, dto: CreateProposalDto) {
    if (
      dto.trainingId !== undefined
      && !(await this.repo.trainingBelongsToTeam(dto.trainingId, teamId))
    ) {
      throw new ForbiddenError('The selected training must belong to the selected team');
    }
    return this.repo.create({
      team_id: teamId,
      training_id: dto.trainingId ?? null,
      proposed_by: proposedBy,
      titre: dto.titre,
      description: dto.description ?? null,
      category: dto.category ?? null,
      objectif: dto.objectif ?? null,
      difficulty: dto.difficulty ?? 'MEDIUM',
      duration_minutes: dto.durationMinutes ?? null,
      visibility: dto.visibility ?? 'TEAM',
      tags: dto.tags ?? [],
      canvas_data: dto.canvasData ?? this.defaultCanvas(dto),
      animation_data: dto.animationData ?? this.defaultAnimation(dto),
      ai_model: this.buildExpertModel(dto),
    });
  }

  async review(id: number, reviewedBy: number, teamId: number, dto: ReviewProposalDto) {
    const proposal = await this.repo.findById(id);
    if (!proposal) throw new NotFoundError('Exercise proposal');
    if (proposal.status !== 'PENDING') throw new BadRequestError('This proposal has already been reviewed');

    if (!(await this.repo.belongsToTeam(id, teamId))) {
      throw new ForbiddenError('You can only review proposals from your own team');
    }

    if (proposal.training_id !== null) {
      if (!(await this.repo.trainingBelongsToTeam(proposal.training_id, teamId))) {
        throw new ForbiddenError('You can only review proposals from your own team');
      }
    }

    return this.repo.review(id, dto.status, reviewedBy, dto.reviewComment);
  }

  private defaultCanvas(dto: CreateProposalDto) {
    return {
      pitch: 'football_2d',
      formation: '4-3-3',
      players: [
        { id: 1, role: 'GK', x: 0.5, y: 0.9 },
        { id: 6, role: 'DM', x: 0.5, y: 0.55 },
        { id: 9, role: 'ST', x: 0.5, y: 0.18 },
      ],
      arrows: [
        { from: { x: 0.5, y: 0.55 }, to: { x: 0.5, y: 0.25 }, label: dto.objectif ?? dto.titre },
      ],
      zones: [{ type: 'pressing', x: 0.35, y: 0.2, width: 0.3, height: 0.2 }],
    };
  }

  private defaultAnimation(dto: CreateProposalDto) {
    return {
      mode: '2D_TIMELINE',
      fps: 12,
      durationSeconds: Math.max(8, Math.min(45, (dto.durationMinutes ?? 12) * 2)),
      keyframes: [
        { t: 0, camera: 'top', note: 'Organisation initiale' },
        { t: 4, camera: 'top', note: 'Deplacement coordonne et appel' },
        { t: 8, camera: 'top', note: 'Decision finale: tir, passe ou fixation' },
      ],
      threeDReady: true,
    };
  }

  private buildExpertModel(dto: CreateProposalDto) {
    const difficulty = dto.difficulty ?? 'MEDIUM';
    const duration = dto.durationMinutes ?? 12;
    const intensity = difficulty === 'ELITE' || difficulty === 'HARD' ? 'HIGH' : duration >= 20 ? 'MEDIUM' : 'CONTROLLED';
    return {
      name: 'FootTech Tactical Exercise Expert v1',
      modelType: 'rule_based_explainable_ai',
      objective: dto.objectif ?? dto.titre,
      tacticalOrientation: dto.category ?? 'Technique et tactique',
      intensity,
      cognitiveLoad: difficulty === 'EASY' ? 'LOW' : difficulty === 'MEDIUM' ? 'MEDIUM' : 'HIGH',
      recommendation: {
        bestMoment: intensity === 'HIGH' ? 'corps_de_seance' : 'echauffement_ou_reactivation',
        coachingFocus: ['prise_information', 'occupation_espace', 'vitesse_decision'],
        riskControl: duration > 25 ? 'prevoir_recuperation_active' : 'charge_maitrisee',
      },
      explainability: [
        'La difficulte ajuste la charge cognitive.',
        'La duree ajuste le risque de fatigue.',
        'Le dessin tactique rend l exercice directement reutilisable.',
      ],
    };
  }
}
