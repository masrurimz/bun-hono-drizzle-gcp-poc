import { Hono } from 'hono';
import { db } from '../../db/db';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { placeholder } from 'drizzle-orm';
import { optionalQueryNumber } from '../../zod';

export const api = new Hono();

const fetchAll = db.query.booking
  .findMany({
    columns: {
      id: true,
      title: true,
      roomId: true,
      userId: true
    },
    with: {
      notifications: {
        columns: {
          title: true,
          type: true
        }
      }
    }
  })
  .prepare('booking_fetchall');

const fetchAllForRoom = db.query.booking
  .findMany({
    columns: {
      id: true,
      title: true,
      roomId: true,
      userId: true
    },
    with: {
      notifications: {
        columns: {
          title: true,
          type: true
        }
      }
    },
    where: (booking, { eq }) => eq(booking.roomId, placeholder('room'))
  })
  .prepare('booking_fetchall_room');

const fetchAllForUser = db.query.booking
  .findMany({
    columns: {
      id: true,
      title: true,
      roomId: true,
      userId: true
    },
    with: {
      notifications: {
        columns: {
          title: true,
          type: true
        }
      }
    },
    where: (booking, { eq }) => eq(booking.userId, placeholder('user'))
  })
  .prepare('booking_fetchall_user');

const fetchAllForRoomUser = db.query.booking
  .findMany({
    columns: {
      id: true,
      title: true,
      roomId: true,
      userId: true
    },
    with: {
      notifications: {
        columns: {
          title: true,
          type: true
        }
      }
    },
    where: (booking, { eq, and }) =>
      and(
        eq(booking.roomId, placeholder('room')),
        eq(booking.userId, placeholder('user'))
      )
  })
  .prepare('booking_fetchall_room_user');

/**
 * @openapi
 * /v0/booking/:
 *   get:
 *     description: Welcome to swagger-jsdoc!
 *     responses:
 *       200:
 *         description: Returns a mysterious string.
 *         content:
 *             application/json:
 *               schema:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: number
 *                     title:
 *                       type: string
 *               example:
 *                 -
 *                   id: 1
 *                   title: "egaegeag"
 *                 -
 *                   id: 2
 *                   title: "EGgyey"
 *
 */
api.get(
  '/',
  zValidator(
    'query',
    z.object({
      user: optionalQueryNumber,
      room: optionalQueryNumber
    })
  ),
  async (c) => {
    const { user, room } = c.req.valid('query');
    if (room) {
      if (user) {
        return c.json(await fetchAllForRoomUser.execute({ user, room }));
      }
      return c.json(await fetchAllForRoom.execute({ room }));
    }

    if (user) {
      return c.json(await fetchAllForUser.execute({ user }));
    }

    return c.json(await fetchAll.execute());
  }
);

api.post('/', async (c) => {});
api.delete('/', async (c) => {});
