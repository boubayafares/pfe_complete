import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
  findById: vi.fn(),
  trainingBelongsToTeam: vi.fn(),
  upsertSlot: vi.fn(),
  update: vi.fn(),
}));

vi.mock('./weekly-plannings.repository.js', () => ({
  WeeklyPlanningsRepository: class {
    findById = mocks.findById;
    trainingBelongsToTeam = mocks.trainingBelongsToTeam;
    upsertSlot = mocks.upsertSlot;
    update = mocks.update;
  },
}));

import { WeeklyPlanningsService } from './weekly-plannings.service.js';

const planning = {
  id: 8,
  team_id: 3,
  season_id: null,
  semaine_numero: null,
  date_debut: new Date('2027-09-06'),
  date_fin: new Date('2027-09-12'),
  nombre_seances: null,
  intensite: null,
  volume: null,
  match_prevu: false,
};

describe('WeeklyPlanningsService tenant integrity', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.findById.mockResolvedValue(planning);
  });

  it('rejects a slot linked to a training owned by another team', async () => {
    mocks.trainingBelongsToTeam.mockResolvedValue(false);
    const service = new WeeklyPlanningsService();

    await expect(service.upsertSlot(8, {
      jour: '2027-09-08',
      moment: 'SOIR',
      trainingId: 99,
    })).rejects.toMatchObject({ statusCode: 403 });
    expect(mocks.upsertSlot).not.toHaveBeenCalled();
  });

  it('allows a training from the planning team', async () => {
    mocks.trainingBelongsToTeam.mockResolvedValue(true);
    mocks.upsertSlot.mockResolvedValue({ id: 1 });
    const service = new WeeklyPlanningsService();

    await expect(service.upsertSlot(8, {
      jour: '2027-09-08',
      moment: 'SOIR',
      trainingId: 12,
    })).resolves.toEqual({ id: 1 });
    expect(mocks.trainingBelongsToTeam).toHaveBeenCalledWith(12, 3);
  });

  it('rejects a partial update that would invert the stored date range', async () => {
    const service = new WeeklyPlanningsService();
    await expect(service.update(8, { dateDebut: '2027-09-20' })).rejects.toMatchObject({
      statusCode: 400,
    });
    expect(mocks.update).not.toHaveBeenCalled();
  });
});
