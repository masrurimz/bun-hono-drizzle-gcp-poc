import { Hono } from 'hono';
import { api as booking } from './booking';

export const apiV0 = new Hono();

apiV0.route('/booking', booking);
