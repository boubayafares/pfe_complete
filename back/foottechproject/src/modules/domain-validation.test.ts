import { describe, expect, it } from 'vitest';
import { broadcastNotificationSchema } from './notifications/notifications.validation.js';
import { createMatchSchema } from './matches/matches.validation.js';
import { createPlayerSchema } from './players/players.validation.js';
import { createSeasonSchema } from './seasons/seasons.validation.js';
import { createTrainingSchema } from './trainings/trainings.validation.js';
import { createWeeklyPlanningSchema } from './weekly-plannings/weekly-plannings.validation.js';
import { bulkMarkAttendanceSchema } from './attendance/attendance.validation.js';

describe('cross-field domain validation', () => {
  it('rejects an inverted season range before PostgreSQL', () => {
    expect(createSeasonSchema.safeParse({
      name: '2027-2028',
      startDate: '2028-06-30',
      endDate: '2027-08-01',
    }).success).toBe(false);
  });

  it('rejects an inverted weekly-planning range before PostgreSQL', () => {
    expect(createWeeklyPlanningSchema.safeParse({
      teamId: 3,
      dateDebut: '2027-09-12',
      dateFin: '2027-09-06',
    }).success).toBe(false);
  });

  it('derives a broadcast team from authentication instead of requiring it in the body', () => {
    const parsed = broadcastNotificationSchema.parse({
      teamId: 999,
      type: 'OTHER',
      title: 'Information',
      message: 'Message',
    });
    expect(parsed).not.toHaveProperty('teamId');
  });

  it('rejects duplicate players in a bulk attendance sheet', () => {
    expect(bulkMarkAttendanceSchema.safeParse({
      entries: [
        { playerId: 7, status: 'PRESENT' },
        { playerId: 7, status: 'ABSENT' },
      ],
    }).success).toBe(false);
  });

  it.each([
    ['player', createPlayerSchema, { firstName: 'A', lastName: 'B', phone: '+33600000000', teamId: 999 }],
    ['training', createTrainingSchema, { date: '2027-09-10', startTime: '18:00', endTime: '19:00', teamId: 999 }],
    ['match', createMatchSchema, { adversaire: 'FC Test', dateHeure: '2027-09-15T18:00:00Z', teamId: 999 }],
    ['weekly planning', createWeeklyPlanningSchema, { dateDebut: '2027-09-06', dateFin: '2027-09-12', teamId: 999 }],
  ])('strips a client-provided teamId from %s creation', (_name, schema, payload) => {
    expect(schema.parse(payload)).not.toHaveProperty('teamId');
  });
});
