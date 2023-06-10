import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { apiV0 } from './v0';
import { app } from '../index';

export const api = new Hono();

api.use('*', cors());
api.onError((err, c) => {
  console.error(err);
  return c.json({ message: 'Internal Server Error', ok: false }, 500);
});

api.get('/', (c) => {
  return c.json(
    app.routes
      // filter out .use('*', cors())
      .filter((r) => r.method !== 'ALL')
      // filter out duplicate routes, happens with validators
      .filter(
        (v, i, a) =>
          a.findIndex((f) => f.path === v.path && f.method === v.method) === i
      )
  );
});

api.route('/v0', apiV0);
