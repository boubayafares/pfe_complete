import { beforeEach, describe, expect, it, vi } from 'vitest';

const db = vi.hoisted(() => ({
  query: vi.fn(),
  withTransaction: vi.fn(),
}));

vi.mock('../config/database.js', () => ({
  query: db.query,
  withTransaction: db.withTransaction,
}));

import { AttendanceRepository } from './attendance/attendance.repository.js';
import { MatchesRepository } from './matches/matches.repository.js';

describe('team roster projections', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('keeps unmarked players visible on a training attendance sheet', async () => {
    const row = {
      id: null,
      training_id: 9,
      player_id: 4,
      status: 'UNMARKED',
      comment: null,
      created_at: null,
      first_name: 'Sara',
      last_name: 'Test',
      numero_maillot: 10,
    };
    db.query.mockResolvedValue({ rows: [row] });

    await expect(new AttendanceRepository().listByTraining(9)).resolves.toEqual([row]);

    const [sql, params] = db.query.mock.calls[0]!;
    expect(sql).toContain('FROM trainings t');
    expect(sql).toContain('LEFT JOIN attendances a');
    expect(sql).toContain("COALESCE(a.status::text, 'UNMARKED')");
    expect(params).toEqual([9]);
  });

  it('keeps players without a saved lineup row available for selection', async () => {
    const row = {
      id: null,
      match_id: 12,
      player_id: 4,
      status: 'NOT_SELECTED',
      position_terrain: null,
      selected_by: null,
      first_name: 'Sara',
      last_name: 'Test',
      numero_maillot: 10,
    };
    db.query.mockResolvedValue({ rows: [row] });

    await expect(new MatchesRepository().getLineup(12)).resolves.toEqual([row]);

    const [sql, params] = db.query.mock.calls[0]!;
    expect(sql).toContain('FROM matches m');
    expect(sql).toContain('LEFT JOIN match_lineups ml');
    expect(sql).toContain("COALESCE(ml.status::text, 'NOT_SELECTED')");
    expect(params).toEqual([12]);
  });
});

describe('match event consistency', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('records a goal and updates the score in one transaction', async () => {
    const event = {
      id: 3,
      match_id: 12,
      event_type: 'GOAL',
      minute: 22,
      player_id: 4,
    };
    const client = {
      query: vi
        .fn()
        .mockResolvedValueOnce({ rows: [event] })
        .mockResolvedValueOnce({ rows: [{ is_home: true }] })
        .mockResolvedValueOnce({ rows: [] }),
    };
    db.withTransaction.mockImplementation(
      async (callback: (transactionClient: typeof client) => Promise<unknown>) =>
        callback(client),
    );

    await expect(
      new MatchesRepository().createEvent(12, {
        event_type: 'GOAL',
        minute: 22,
        player_id: 4,
      }),
    ).resolves.toEqual(event);

    expect(db.withTransaction).toHaveBeenCalledOnce();
    expect(client.query).toHaveBeenCalledTimes(3);
    expect(client.query.mock.calls[1]?.[0]).toContain('FOR UPDATE');
    expect(client.query.mock.calls[2]?.[0]).toContain('home_score = home_score + 1');
  });
});
