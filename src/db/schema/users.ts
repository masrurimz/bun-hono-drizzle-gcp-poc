import {
  customType,
  integer,
  sqliteTable,
  text
} from 'drizzle-orm/sqlite-core';
import { InferModel, relations, sql } from 'drizzle-orm';
import { posts } from './posts';

const customTimestamp = customType<{
  data: Date;
  driverData: string;
  config: { withTimezone: boolean; precision?: number };
}>({
  dataType(config) {
    const precision =
      typeof config?.precision !== 'undefined' ? ` (${config.precision})` : '';
    return `timestamp${precision}${
      config?.withTimezone ? ' with time zone' : ''
    }`;
  },
  fromDriver(value: string): Date {
    return new Date(value);
  }
});
export const users = sqliteTable('users', {
  id: integer('id').primaryKey(),
  fullName: text('full_name').notNull(),
  phone: text('phone', { length: 256 }).notNull(),
  createdAt: customTimestamp('created_at', { withTimezone: true })
    .notNull()
    .default(sql`CURRENT_TIMESTAMP`)
});

export type User = InferModel<typeof users>;
export type InsertUser = InferModel<typeof users, 'insert'>;

export const usersRelations = relations(users, ({ many }) => ({
  posts: many(posts)
}));
