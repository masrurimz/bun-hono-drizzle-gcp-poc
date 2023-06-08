import { drizzle } from 'drizzle-orm/postgres-js';
import schema from './schema/schema';
import postgres from 'postgres';

const { PG_URL, PG_HOST, PG_USER, PG_PASSWORD, PG_DB } = Bun.env;

let pg_connect:
  | { user: string; password: string; host: string; database: string }
  | string
  | null = null;

if (
  PG_HOST !== undefined &&
  PG_USER !== undefined &&
  PG_PASSWORD !== undefined &&
  PG_DB !== undefined
) {
  pg_connect = {
    user: PG_USER,
    host: PG_HOST,
    password: PG_PASSWORD,
    database: PG_DB
  };
}

if (PG_URL !== undefined) {
  pg_connect = PG_URL;
}

if (pg_connect === null) {
  console.error('PG_URL is not defined!');
  process.exit(1);
}

// @ts-ignore
const queryClient = postgres(pg_connect);
export const db = drizzle(queryClient, { schema });
