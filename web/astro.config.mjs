import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import sitemap from '@astrojs/sitemap';
import mdx from '@astrojs/mdx';

const now = new Date().toISOString();

export default defineConfig({
  site: 'https://drawbell.kashifkhan.dev',
  integrations: [
    tailwind({ applyBaseStyles: false }),
    sitemap({
      changefreq: 'weekly',
      priority: 0.7,
      lastmod: new Date(),
      customPages: [],
      serialize(item) {
        if (item.url === 'https://drawbell.kashifkhan.dev/') {
          return { ...item, changefreq: 'daily', priority: 1.0, lastmod: now };
        }
        if (item.url === 'https://drawbell.kashifkhan.dev/blog/') {
          return { ...item, changefreq: 'daily', priority: 0.9, lastmod: now };
        }
        if (item.url === 'https://drawbell.kashifkhan.dev/download/') {
          return { ...item, changefreq: 'weekly', priority: 0.8, lastmod: now };
        }
        if (item.url.includes('/blog/')) {
          return { ...item, changefreq: 'monthly', priority: 0.7 };
        }
        return item;
      },
    }),
    mdx(),
  ],
  output: 'static',
});
