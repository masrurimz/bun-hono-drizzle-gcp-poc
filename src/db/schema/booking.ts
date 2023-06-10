import { integer, pgTable, text, timestamp } from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';
import { notification } from './notification';
import { audit } from './audit';

export const booking = pgTable('bookings', {
  ...audit,
  // TODO: get real type from user service
  userId: integer('user_id').notNull(),
  start: timestamp('start').notNull(),
  end: timestamp('end').notNull(),
  // TODO: get real type from room service
  roomId: integer('room_id').notNull(),
  title: text('title').notNull(),
  description: text('description')
});

export const bookingRelations = relations(booking, ({ many }) => ({
  notifications: many(notification)
}));
