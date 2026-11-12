import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
  query: vi.fn(),
  bulkUpsert: vi.fn(),
}));

vi.mock('../../config/database.js', () => ({
  query: mocks.query,
}));

vi.mock('./attendance.repository.js', () => ({
  AttendanceRepository: class {
    bulkUpsert = mocks.bulkUpsert;
  },
}));

import { AttendanceService } from './attendance.service.js';

const entries = [
  { playerId: 4, status: 'PRESENT' as const },
  { playerId: 5, status: 'LATE' as const, comment: 'Transport' },
];

describe('AttendanceService bulk integrity', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('validates every player before starting the atomic bulk write', async () => {
    mocks.query
      .mockResolvedValueOnce({ rowCount: 1, rows: [{ exists: 1 }] })
      .mockResolvedValueOnce({ rowCount: 2, rows: [{ id: 4 }, { id: 5 }] });
    mocks.bulkUpsert.mockResolvedValue([{ id: 1 }, { id: 2 }]);
    const service = new AttendanceService();

    await expect(service.bulkMark(9, entries)).resolves.toHaveLength(2);
    expect(mocks.bulkUpsert).toHaveBeenCalledWith(9, entries);
  });

  it('writes nothing when one player belongs to another team', async () => {
    mocks.query
      .mockResolvedValueOnce({ rowCount: 1, rows: [{ exists: 1 }] })
      .mockResolvedValueOnce({ rowCount: 1, rows: [{ id: 4 }] });
    const service = new AttendanceService();

    await expect(service.bulkMark(9, entries)).rejects.toMatchObject({ statusCode: 403 });
    expect(mocks.bulkUpsert).not.toHaveBeenCalled();
  });
});
