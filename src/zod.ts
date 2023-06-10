import { z } from 'zod';

export const optionalQueryNumber = z
  .string()
  .optional()
  .transform((v) => (v === undefined ? undefined : Number(v)))
  .superRefine((v, ctx) => {
    const parse = z.number().positive().int().optional().safeParse(v);
    if (!parse.success) {
      parse.error.errors.forEach((e) => ctx.addIssue(e));
    }
  });
