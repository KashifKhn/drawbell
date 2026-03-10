import { defineCollection, z } from 'astro:content';

const blog = defineCollection({
  type: 'content',
  schema: z.object({
    title:         z.string(),
    description:   z.string(),
    publishedDate: z.date(),
    updatedDate:   z.date().optional(),
    author:        z.string().default('Kashif Khan'),
    tags:          z.array(z.string()).default([]),
    image:         z.string().optional(),
    draft:         z.boolean().default(false),
  }),
});

export const collections = { blog };
