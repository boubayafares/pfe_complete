describe('API Health Checks', () => {
  it('Backend API is healthy', () => {
    cy.request(`${Cypress.env('API_URL')}/health`).then((response) => {
      expect(response.status).to.eq(200);
      expect(response.body.status).to.eq('ok');
    });
  });

  it('AI insights remain private behind the authenticated Express proxy', () => {
    cy.request({
      method: 'GET',
      url: `${Cypress.env('API_URL')}/api/v1/ai-insights/clusters?nClusters=2`,
      failOnStatusCode: false,
    }).then((response) => {
      expect(response.status).to.eq(401);
    });
  });
});

describe('Auth Flow', () => {
  it('Login fails with invalid credentials', () => {
    cy.request({
      method: 'POST',
      url: `${Cypress.env('API_URL')}/api/v1/auth/login`,
      body: { email: 'nonexistent@test.com', password: 'wrong' },
      failOnStatusCode: false,
    }).then((response) => {
      expect(response.status).to.be.oneOf([400, 401, 422]);
    });
  });
});
