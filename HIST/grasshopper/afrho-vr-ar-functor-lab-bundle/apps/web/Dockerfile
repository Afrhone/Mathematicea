FROM node:22-alpine AS deps
WORKDIR /app
COPY apps/web/package.json ./
RUN npm install
COPY apps/web ./
RUN npm run build

FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=deps /app ./
CMD ["npm", "run", "start"]
