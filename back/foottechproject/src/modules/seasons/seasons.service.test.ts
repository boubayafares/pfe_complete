import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
  findAccessible: vi.fn(),
  findAccessibleById: vi.fn(),
  findOwnedById: vi.fn(),
  findByName: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
  delete: vi.fn(),
  setCurrent: vi.fn(),
}));

vi.mock('./seasons.repository.js', () => ({
  SeasonsRepository: class {
    findAccessible = mocks.findAccessible;
    findAccessibleById = mocks.findAccessibleById;
    findOwnedById = mocks.findOwnedById;
    findByName = mocks.findByName;
    create = mocks.create;
    update = mocks.update;
    delete = mocks.delete;
    setCurrent = mocks.setCurrent;
  },
}));

import { SeasonsService } from './seasons.service.js';

const ownedSeason = {
  id: 7,
  team_id: 3,
  name: '2027/2028',
  start_date: new Date('2027-08-01'),
  end_date: new Date('2028-06-30'),
  is_current: false,
};

describe('SeasonsService tenant integrity', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.findAccessibleById.mockResolvedValue(ownedSeason);
    mocks.findOwnedById.mockResolvedValue(ownedSeason);
    mocks.findByName.mockResolvedValue(null);
  });

  it('lists only seasons accessible to the selected team', async () => {
    mocks.findAccessible.mockResolvedValue([ownedSeason]);
    const service = new SeasonsService();

    await expect(service.list(3)).resolves.toEqual([ownedSeason]);
    expect(mocks.findAccessible).toHaveBeenCalledWith(3);
  });

  it('creates a season owned by the selected team', async () => {
    mocks.create.mockResolvedValue(ownedSeason);
    const service = new SeasonsService();

    await service.create({
      name: '2027/2028',
      startDate: '2027-08-01',
      endDate: '2028-06-30',
    }, 3);

    expect(mocks.findByName).toHaveBeenCalledWith('2027/2028', 3);
    expect(mocks.create).toHaveBeenCalledWith(expect.objectContaining({ team_id: 3 }));
  });

  it('keeps the current-season switch scoped to the selected team', async () => {
    mocks.create.mockResolvedValue(ownedSeason);
    mocks.setCurrent.mockResolvedValue({ ...ownedSeason, is_current: true });
    const service = new SeasonsService();

    await service.create({
      name: '2027/2028',
      startDate: '2027-08-01',
      endDate: '2028-06-30',
      isCurrent: true,
    }, 3);

    expect(mocks.setCurrent).toHaveBeenCalledWith(7, 3);
  });

  it('does not allow a coach to mutate a legacy shared season', async () => {
    mocks.findAccessibleById.mockResolvedValue({ ...ownedSeason, team_id: null });
    mocks.findOwnedById.mockResolvedValue(null);
    const service = new SeasonsService();

    await expect(service.update(7, { name: '2028/2029' }, 3)).rejects.toMatchObject({
      statusCode: 403,
    });
    expect(mocks.update).not.toHaveBeenCalled();
  });

  it('can explicitly unset the current season flag', async () => {
    mocks.update.mockResolvedValue({ ...ownedSeason, is_current: false });
    const service = new SeasonsService();

    await service.update(7, { isCurrent: false }, 3);

    expect(mocks.update).toHaveBeenCalledWith(7, { is_current: false });
    expect(mocks.setCurrent).not.toHaveBeenCalled();
  });
});
