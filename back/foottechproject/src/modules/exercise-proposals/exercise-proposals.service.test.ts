import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
  create: vi.fn(),
  trainingBelongsToTeam: vi.fn(),
  findById: vi.fn(),
  belongsToTeam: vi.fn(),
}));

vi.mock('./exercise-proposals.repository.js', () => ({
  ExerciseProposalsRepository: class {
    create = mocks.create;
    trainingBelongsToTeam = mocks.trainingBelongsToTeam;
    findById = mocks.findById;
    belongsToTeam = mocks.belongsToTeam;
  },
}));

import { ExerciseProposalsService } from './exercise-proposals.service.js';

describe('ExerciseProposalsService tenant integrity', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.create.mockResolvedValue({ id: 1 });
  });

  it('stores an unlinked proposal under the selected team', async () => {
    const service = new ExerciseProposalsService();

    await service.create(10, 3, { titre: 'Conservation du ballon' });

    expect(mocks.create).toHaveBeenCalledWith(expect.objectContaining({
      team_id: 3,
      training_id: null,
      proposed_by: 10,
    }));
  });

  it('allows a proposal linked to a training from the selected team', async () => {
    mocks.trainingBelongsToTeam.mockResolvedValue(true);
    const service = new ExerciseProposalsService();

    await service.create(10, 3, { trainingId: 8, titre: 'Pressing' });

    expect(mocks.trainingBelongsToTeam).toHaveBeenCalledWith(8, 3);
    expect(mocks.create).toHaveBeenCalledWith(expect.objectContaining({
      team_id: 3,
      training_id: 8,
    }));
  });

  it('rejects a training owned by another team', async () => {
    mocks.trainingBelongsToTeam.mockResolvedValue(false);
    const service = new ExerciseProposalsService();

    await expect(service.create(10, 3, {
      trainingId: 99,
      titre: 'Cross-tenant',
    })).rejects.toMatchObject({ statusCode: 403 });
    expect(mocks.create).not.toHaveBeenCalled();
  });

  it('creates an explainable tactical model with visual defaults', async () => {
    const service = new ExerciseProposalsService();

    await service.create(10, 3, {
      titre: 'Sortie de pressing',
      objectif: 'Progresser sous pression',
      category: 'TRANSITION',
      difficulty: 'ELITE',
      durationMinutes: 24,
      visibility: 'COMMUNITY',
      tags: ['pressing', 'transition'],
    });

    expect(mocks.create).toHaveBeenCalledWith(expect.objectContaining({
      visibility: 'COMMUNITY',
      tags: ['pressing', 'transition'],
      canvas_data: expect.objectContaining({ formation: '4-3-3' }),
      animation_data: expect.objectContaining({ mode: '2D_TIMELINE', threeDReady: true }),
      ai_model: expect.objectContaining({
        modelType: 'rule_based_explainable_ai',
        intensity: 'HIGH',
        objective: 'Progresser sous pression',
      }),
    }));
  });

  it('allows another team to read a validated community exercise', async () => {
    mocks.findById.mockResolvedValue({
      id: 42,
      status: 'VALIDATED',
      visibility: 'COMMUNITY',
    });
    mocks.belongsToTeam.mockResolvedValue(false);

    const proposal = await new ExerciseProposalsService().getById(42, 99);

    expect(proposal).toMatchObject({ id: 42, visibility: 'COMMUNITY' });
    expect(mocks.belongsToTeam).toHaveBeenCalledWith(42, 99);
  });
});
