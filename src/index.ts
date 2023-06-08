import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { db } from './db/db';

const app = new Hono();

app.notFound((c) => c.json({ message: 'Not Found', ok: false }, 404));
app.get('/', (c) => c.text('Hello Hono!'));

const api = new Hono();
api.use('/posts/*', cors());
api.onError((err, c) => {
  console.error(err);
  return c.json({ message: 'Internal Server Error', ok: false }, 500);
});

app.use('*', logger());

api.get('/posts', async (c) => {
  const { limit, offset } = c.req.query();
  console.log(limit, offset);
  // const id = db
  //   .insert(users)
  //   .values({ fullName: 'aa', phone: 'ega' })
  //   .returning({ id: users.id })
  //   .all();
  // console.log(id);
  const posts = await db.query.users.findMany({
    with: {
      posts: {
        columns: {
          title: true,
          message: true
        }
      }
    },
    columns: {
      fullName: true,
      createdAt: true
    },
    limit: parseInt(limit) || undefined
  });
  console.log(posts);
  return c.json({ posts });
});

app.route('/api', api);
export default {
  fetch: app.fetch,
  port: process.env.PORT || 3000
};
