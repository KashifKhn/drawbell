/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,ts,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        brand: {
          DEFAULT: '#D94A09',
          50:  '#FEF0EB',
          100: '#FCD8CA',
          200: '#F8AC90',
          300: '#F47E57',
          400: '#F05A1A',
          500: '#D94A09',
          600: '#B33A07',
          700: '#8C2C05',
          800: '#661E04',
          900: '#3F1102',
        },
      },
      fontFamily: {
        display: ['Space Grotesk', 'sans-serif'],
        sans:    ['DM Sans', 'sans-serif'],
        mono:    ['JetBrains Mono', 'monospace'],
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'float':      'float 6s ease-in-out infinite',
        'glow':       'glow 3s ease-in-out infinite',
      },
      keyframes: {
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%':      { transform: 'translateY(-8px)' },
        },
        glow: {
          '0%, 100%': { boxShadow: '0 0 20px rgba(217,74,9,0.3)' },
          '50%':      { boxShadow: '0 0 40px rgba(217,74,9,0.6)' },
        },
      },
    },
  },
  plugins: [],
};
