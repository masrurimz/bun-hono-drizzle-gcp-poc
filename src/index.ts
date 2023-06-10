import { Hono } from 'hono';
import { logger } from 'hono/logger';
import { serveStatic } from 'hono/bun';
import { api } from './api';

export const app = new Hono({ strict: false });

app.notFound((c) => c.json({ message: 'Not Found', ok: false }, 404));
app.get('/', (c) => c.text('Hello Hono!'));

app.use('*', logger());
app.get('/swagger.json', serveStatic({ path: './src/swagger.json' }));

app.route('/api', api);

export default {
  fetch: app.fetch,
  port: process.env.PORT || 3000
};
