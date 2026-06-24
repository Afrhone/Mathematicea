# syntax=docker/dockerfile:1
FROM node:20-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY server.js ./
COPY public ./public
ENV PORT=8877
EXPOSE 8877
CMD ["npm", "start"]
