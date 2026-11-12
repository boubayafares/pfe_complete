import { test, expect, type APIRequestContext } from '@playwright/test';

const email = process.env.E2E_EMAIL ?? '';
const password = process.env.E2E_PASSWORD ?? '';

async function postData(request: APIRequestContext, path: string, data: unknown, token: string, expected = 201) {
  const response = await request.post(path, {
    data,
    headers: { Authorization: `Bearer ${token}` },
  });
  expect(response.status(), `${path}: ${await response.text()}`).toBe(expected);
  return (await response.json()).data;
}

test.describe('Coach business journey — Flutter-facing API', () => {
  test.skip(!email || !password, 'E2E_EMAIL/E2E_PASSWORD are provided by the isolated CI fixture');

  test('team, players, training, weekly plan, match, AI, PDF and refresh-token rotation', async ({ request }, testInfo) => {
    test.setTimeout(45_000);
    const runId = `${Date.now()}-${testInfo.retry}`;
    const phoneSerial = String(Date.now() % 10_000_000).padStart(7, '0');

    const login = await request.post('/api/v1/auth/login', { data: { email, password } });
    expect(login.status()).toBe(200);
    const loginData = (await login.json()).data;
    let accessToken = loginData.tokens.accessToken as string;
    const refreshToken = loginData.tokens.refreshToken as string;
    let auth = { Authorization: `Bearer ${accessToken}` };

    const team = await postData(request, '/api/v1/teams', {
      name: `FootTech CI ${runId}`, category: 'U17', description: 'Disposable integration fixture',
    }, accessToken);
    const season = await postData(request, '/api/v1/seasons', {
      name: `CI-${runId}`, startDate: '2027-08-01', endDate: '2028-06-30', isCurrent: false,
    }, accessToken);

    const positions = ['GK', 'CB', 'MF', 'FW'];
    const playerIds: number[] = [];
    for (let index = 0; index < positions.length; index += 1) {
      const player = await postData(request, '/api/v1/players', {
        firstName: `CIPlayer${index + 1}`,
        lastName: 'FootTech',
        phone: `+3369${phoneSerial.slice(0, 6)}${index + 1}`,
        dateNaissance: '2010-01-01',
        posteP: positions[index],
        piedFort: 'DROIT',
        numeroMaillot: index + 1,
      }, accessToken);
      expect(['SENT', 'FAILED']).toContain(player.activationDelivery);
      playerIds.push(player.id);
    }

    const training = await postData(request, '/api/v1/trainings', {
      date: '2027-09-10',
      startTime: '18:00',
      endTime: '19:30',
      location: 'CI training ground',
    }, accessToken);
    await postData(request, `/api/v1/attendance/trainings/${training.id}/bulk`, {
      entries: playerIds.map((playerId) => ({ playerId, status: 'PRESENT', comment: 'CI E2E' })),
    }, accessToken);

    const weeklyPlan = await postData(request, '/api/v1/weekly-plannings', {
      seasonId: season.id,
      dateDebut: '2027-09-06',
      dateFin: '2027-09-12',
      nombreSeances: 1,
      intensite: 'MOYENNE',
      volume: 'MODERE',
      matchPrevu: false,
    }, accessToken);
    const updatedWeeklyPlan = await request.patch(`/api/v1/weekly-plannings/${weeklyPlan.id}`, {
      headers: auth,
      data: { volume: 'ELEVE' },
    });
    expect(updatedWeeklyPlan.status(), await updatedWeeklyPlan.text()).toBe(200);
    expect((await updatedWeeklyPlan.json()).data.volume).toBe('ELEVE');
    const weeklySlot = await request.put(`/api/v1/weekly-plannings/${weeklyPlan.id}/slots`, {
      headers: auth,
      data: {
        jour: '2027-09-10',
        moment: 'SOIR',
        trainingId: training.id,
        description: 'Séance CI liée au planning',
      },
    });
    expect(weeklySlot.status(), await weeklySlot.text()).toBe(200);
    expect((await weeklySlot.json()).data.training_id).toBe(training.id);

    const secondTeam = await postData(request, '/api/v1/teams', {
      name: `FootTech CI B ${runId}`, category: 'U19', description: 'Second isolated team',
    }, accessToken);
    const selectSecondTeam = await request.post('/api/v1/auth/select-team', {
      headers: auth,
      data: { teamId: secondTeam.id },
    });
    expect(selectSecondTeam.status(), await selectSecondTeam.text()).toBe(200);
    const selectedData = (await selectSecondTeam.json()).data;
    expect(selectedData.user.teamId).toBe(secondTeam.id);
    const selectUnknownTeam = await request.post('/api/v1/auth/select-team', {
      headers: auth,
      data: { teamId: 9_999_999 },
    });
    expect(selectUnknownTeam.status()).toBe(403);

    const refreshedSelection = await request.post('/api/v1/auth/refresh', {
      data: { refreshToken: selectedData.tokens.refreshToken },
    });
    expect(refreshedSelection.status(), await refreshedSelection.text()).toBe(200);
    const secondTeamToken = (await refreshedSelection.json()).data.accessToken as string;
    const secondTeamAuth = { Authorization: `Bearer ${secondTeamToken}` };
    const secondTeamPlayers = await request.get('/api/v1/players', { headers: secondTeamAuth });
    expect(secondTeamPlayers.status()).toBe(200);
    expect((await secondTeamPlayers.json()).data).toHaveLength(0);
    const secondTeamSeasons = await request.get('/api/v1/seasons', { headers: secondTeamAuth });
    expect(secondTeamSeasons.status()).toBe(200);
    expect((await secondTeamSeasons.json()).data).toHaveLength(0);
    const crossTeamSeason = await request.get(`/api/v1/seasons/${season.id}`, {
      headers: secondTeamAuth,
    });
    expect(crossTeamSeason.status()).toBe(404);
    const crossTeamSeasonMatch = await request.post('/api/v1/matches', {
      headers: secondTeamAuth,
      data: {
        seasonId: season.id,
        adversaire: 'Forbidden cross-team season',
        dateHeure: '2027-09-16T18:00:00Z',
      },
    });
    expect(crossTeamSeasonMatch.status()).toBe(403);
    const secondTeamSeason = await postData(request, '/api/v1/seasons', {
      name: season.name,
      startDate: '2027-08-01',
      endDate: '2028-06-30',
      isCurrent: true,
    }, secondTeamToken);
    expect(secondTeamSeason.team_id).toBe(secondTeam.id);

    const secondTraining = await postData(request, '/api/v1/trainings', {
      date: '2027-09-11',
      startTime: '17:00',
      endTime: '18:00',
      location: 'Second-team ground',
    }, secondTeamToken);
    expect(secondTraining.team_id).toBe(secondTeam.id);
    const crossTeamTraining = await request.get(`/api/v1/trainings/${training.id}`, {
      headers: secondTeamAuth,
    });
    expect(crossTeamTraining.status()).toBe(403);

    const selectFirstTeam = await request.post('/api/v1/auth/select-team', {
      headers: secondTeamAuth,
      data: { teamId: team.id },
    });
    expect(selectFirstTeam.status(), await selectFirstTeam.text()).toBe(200);
    const firstTeamSession = (await selectFirstTeam.json()).data;
    accessToken = firstTeamSession.tokens.accessToken as string;
    auth = { Authorization: `Bearer ${accessToken}` };
    const firstTeamPlayers = await request.get('/api/v1/players', { headers: auth });
    expect(firstTeamPlayers.status()).toBe(200);
    expect((await firstTeamPlayers.json()).data).toHaveLength(4);
    const firstTeamSeasons = await request.get('/api/v1/seasons', { headers: auth });
    expect(firstTeamSeasons.status()).toBe(200);
    expect((await firstTeamSeasons.json()).data.map((item: { id: number }) => item.id)).toEqual([season.id]);

    const match = await postData(request, '/api/v1/matches', {
      seasonId: season.id,
      adversaire: 'CI United',
      dateHeure: '2027-09-15T18:00:00Z',
      lieu: 'CI stadium',
      isHome: true,
      formation: '4-3-3',
    }, accessToken);

    const lineup = await request.put(`/api/v1/matches/${match.id}/lineup`, {
      headers: auth,
      data: {
        entries: playerIds.map((playerId, index) => ({
          playerId, status: 'STARTER', positionTerrain: positions[index],
        })),
      },
    });
    expect(lineup.status()).toBe(200);

    const recommendations = await request.post(`/api/v1/matches/${match.id}/ai-recommendations`, {
      headers: auth,
      data: { playerIds },
    });
    expect(recommendations.status(), await recommendations.text()).toBe(200);
    const recommendationData = (await recommendations.json()).data as unknown[];
    expect(recommendationData.length).toBeGreaterThan(0);

    const stored = await request.get(`/api/v1/matches/${match.id}/ai-recommendations`, { headers: auth });
    expect(stored.status()).toBe(200);
    expect((await stored.json()).data).toHaveLength(recommendationData.length);

    const clusters = await request.get('/api/v1/ai-insights/clusters?nClusters=2', { headers: auth });
    expect(clusters.status(), await clusters.text()).toBe(200);
    expect((await clusters.json()).data.assignments).toHaveLength(4);

    const tone = await request.post('/api/v1/ai-insights/tone', {
      headers: auth,
      data: { comment: 'Très bon effort collectif, continuez ainsi.' },
    });
    expect(tone.status()).toBe(200);
    expect((await tone.json()).data.flag).toBe('OK');

    const generatedReport = await request.post(`/api/v1/matches/${match.id}/report/generate`, {
      headers: auth,
      data: {},
    });
    expect(generatedReport.status()).toBe(201);
    const reportFile = await request.get(`/api/v1/matches/${match.id}/report/file`, { headers: auth });
    expect(reportFile.status()).toBe(200);
    expect(reportFile.headers()['content-type']).toContain('application/pdf');
    expect((await reportFile.body()).subarray(0, 4).toString()).toBe('%PDF');

    const rotated = await request.post('/api/v1/auth/refresh', { data: { refreshToken } });
    expect(rotated.status()).toBe(200);
    const oldTokenReuse = await request.post('/api/v1/auth/refresh', { data: { refreshToken } });
    expect(oldTokenReuse.status()).toBe(401);
  });
});
