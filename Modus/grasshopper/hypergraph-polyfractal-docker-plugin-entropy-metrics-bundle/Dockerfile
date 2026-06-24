# syntax=docker/dockerfile:1
FROM node:20-bookworm AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install

FROM node:20-bookworm AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:20-bookworm AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY ./server ./server
COPY ./plugins ./plugins
COPY ./module ./module
COPY ./config ./config
RUN mkdir -p /data
EXPOSE 8787
CMD ["node", "server/server.js"]
