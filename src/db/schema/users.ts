import { pgTable, serial, text, timestamp, varchar } from 'drizzle-orm/pg-core';
import { InferModel, relations } from 'drizzle-orm';
import { posts } from './posts';

export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  fullName: text('full_name').notNull(),
  phone: varchar('phone', { length: 256 }).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true })
    .notNull()
    .defaultNow()
});

export type User = InferModel<typeof users>;
export type InsertUser = InferModel<typeof users, 'insert'>;

export const usersRelations = relations(users, ({ many }) => ({
  posts: many(posts)
}));
