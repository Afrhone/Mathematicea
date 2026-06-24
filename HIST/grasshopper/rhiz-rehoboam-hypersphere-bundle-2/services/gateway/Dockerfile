FROM node:24-bookworm-slim
WORKDIR /app
COPY services/gateway/package.json ./package.json
RUN npm install --omit=dev
COPY services/gateway/src ./src
COPY personas ./personas
CMD ["npm","start"]
