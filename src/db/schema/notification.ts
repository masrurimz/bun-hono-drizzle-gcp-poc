import { boolean, integer, pgEnum, pgTable, text } from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';
import { booking } from './booking';
import { audit } from './audit';

export const notificationType = pgEnum('notification_type', [
  'REMINDER',
  'OTHER'
]);

export type NotificationType = (typeof notificationType.enumValues)[number];

export const notification = pgTable('notification', {
  ...audit,
  bookingId: integer('booking_id')
    .notNull()
    .references(() => booking.id, { onDelete: 'cascade', onUpdate: 'cascade' }),
  // TODO: get real type from user service
  userId: integer('user_id').notNull(),
  isRead: boolean('is_read').notNull().default(false),
  title: text('title').notNull(),
  message: text('message').notNull(),
  type: notificationType('type').notNull().default('OTHER')
});

export const notificationsRelations = relations(notification, ({ one }) => ({
  booking: one(booking, {
    fields: [notification.bookingId],
    references: [booking.id]
  })
}));
