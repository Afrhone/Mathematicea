FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json ./
RUN npm install
FROM node:22-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ARG NEXT_PUBLIC_GUARDIAN_API_URL=http://localhost:8450
ENV NEXT_PUBLIC_GUARDIAN_API_URL=$NEXT_PUBLIC_GUARDIAN_API_URL
RUN mkdir -p app && \
    test -f app/globals.css || printf '%s\n' \
      '* { box-sizing: border-box; }' \
      'html, body { margin: 0; padding: 0; min-height: 100%; background: #05070a; color: #e5f2ff; font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }' \
      'body { min-height: 100vh; }' \
      'a { color: inherit; text-decoration: none; }' \
      'button, input, textarea, select { font: inherit; }' \
      'main { min-height: 100vh; }' \
      > app/globals.css && \
    printf '%s\n' \
      "declare module '*.css';" \
      "declare module '*.scss';" \
      "declare module '*.sass';" \
      > global.d.ts && \
    printf '%s\n' \
      '{' \
      '  "compilerOptions": {' \
      '    "target": "ES2017",' \
      '    "lib": ["dom", "dom.iterable", "esnext"],' \
      '    "allowJs": true,' \
      '    "skipLibCheck": true,' \
      '    "strict": false,' \
      '    "noEmit": true,' \
      '    "esModuleInterop": true,' \
      '    "module": "esnext",' \
      '    "moduleResolution": "bundler",' \
      '    "resolveJsonModule": true,' \
      '    "isolatedModules": true,' \
      '    "jsx": "preserve",' \
      '    "incremental": true,' \
      '    "allowArbitraryExtensions": true,' \
      '    "noUncheckedSideEffectImports": false,' \
      '    "plugins": [{"name": "next"}]' \
      '  },' \
      '  "include": ["next-env.d.ts", "global.d.ts", "**/*.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],' \
      '  "exclude": ["node_modules"]' \
      '}' \
      > tsconfig.json
RUN npm run build
FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app ./
EXPOSE 3000
CMD ["npm","run","start"]
