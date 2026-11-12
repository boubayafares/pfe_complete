import { env } from './env.js';

export const swaggerSpec = {
  openapi: '3.0.3',
  info: {
    title: 'FootTech v2 API',
    version: '2.0.0',
    description: 'REST API for FootTech — Coach / Adjoint / Joueur.',
  },
  servers: [{ url: `http://localhost:${env.PORT}`, description: 'Local' }],
  components: {
    securitySchemes: { bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' } },
    schemas: {
      Error: {
        type: 'object',
        properties: {
          success: { type: 'boolean', example: false },
          message: { type: 'string' },
        },
      },
    },
  },
  security: [{ bearerAuth: [] }],
  paths: {
    '/health': {
      get: {
        summary: 'Service health check',
        security: [],
        responses: { '200': { description: 'Service is healthy' } },
      },
    },
    '/api/v1/auth/register-coach': {
      post: {
        summary: 'Register a coach account',
        security: [],
        responses: {
          '201': { description: 'Coach registered' },
          '400': { description: 'Invalid request' },
          '409': { description: 'Account already exists' },
        },
      },
    },
    '/api/v1/auth/login': {
      post: {
        summary: 'Authenticate a coach or assistant',
        security: [],
        responses: {
          '200': { description: 'Authentication tokens issued' },
          '401': { description: 'Invalid credentials' },
          '429': { description: 'Too many attempts' },
        },
      },
    },
    '/api/v1/auth/refresh': {
      post: {
        summary: 'Rotate a refresh token',
        security: [],
        responses: {
          '200': { description: 'New token pair issued' },
          '401': { description: 'Invalid or revoked refresh token' },
        },
      },
    },
    '/api/v1/ai-insights/players/{id}/trend': {
      get: {
        summary: 'Get the performance trend of an accessible player',
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
        responses: {
          '200': { description: 'Player trend' },
          '403': { description: 'Player is outside the authenticated team' },
        },
      },
    },
    '/api/v1/ai-insights/clusters': {
      get: {
        summary: 'Cluster players in the authenticated team',
        parameters: [{ name: 'nClusters', in: 'query', schema: { type: 'integer', minimum: 2, maximum: 8, default: 3 } }],
        responses: { '200': { description: 'Team player clusters' } },
      },
    },
    '/api/v1/ai-insights/tone': {
      post: {
        summary: 'Analyze the tone of a comment',
        responses: { '200': { description: 'Tone analysis' } },
      },
    },
    '/api/v1/ai-insights/expert-project-model': {
      get: {
        summary: 'Get the explainable FootTech expert model for the team',
        description: 'Returns maturity signals and capabilities for tactics, attendance, analytics and communication.',
        responses: {
          '200': { description: 'Expert project model' },
          '401': { description: 'No team is associated with the account' },
          '403': { description: 'Coach or assistant role required' },
        },
      },
    },
    '/api/v1/exercise-proposals/library': {
      get: {
        summary: 'List validated team and community exercises',
        description: 'Read-only endpoint available to coach, assistant and player.',
        responses: {
          '200': { description: 'Tactical exercise library' },
          '403': { description: 'Role is not allowed' },
        },
      },
    },
    '/api/v1/notifications/convocations': {
      post: {
        summary: 'Send a team convocation',
        description: 'Validates target ownership, persists APP notifications and processes Email/SMS best-effort.',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['targetType', 'targetId'],
                properties: {
                  targetType: { type: 'string', enum: ['MATCH', 'TRAINING'] },
                  targetId: { type: 'integer', minimum: 1 },
                  title: { type: 'string' },
                  message: { type: 'string' },
                  channels: { type: 'array', items: { type: 'string', enum: ['APP', 'EMAIL', 'SMS'] } },
                },
              },
            },
          },
        },
        responses: {
          '200': { description: 'Convocation processed' },
          '404': { description: 'Target does not belong to the team' },
        },
      },
    },
    '/api/v1/attendance/trainings/{id}/bulk': {
      post: {
        summary: 'Mark attendance for multiple players atomically',
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }],
        responses: {
          '201': { description: 'Attendance saved and broadcast through Socket.IO' },
          '403': { description: 'Training or player is outside the authenticated team' },
        },
      },
    },
  },
} as const;
