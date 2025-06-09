# STAGE 1: BASE (install deps for sharp, puppeteer, chromium)
FROM node:22.15.0-alpine AS base

WORKDIR /usr/src/wpp-server

ENV NODE_ENV=production \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

COPY package.json ./

RUN apk update && \
    apk add --no-cache \
    vips-dev \
    fftw-dev \
    gcc \
    g++ \
    make \
    libc6-compat \
    python3 \
    chromium \
    nss \
    yarn \
    && rm -rf /var/cache/apk/*

# Instala dependências do Node.js
RUN yarn install --production --pure-lockfile && \
    yarn add sharp --ignore-engines && \
    yarn cache clean

# STAGE 2: BUILD
FROM base AS build
WORKDIR /usr/src/wpp-server

COPY package.json ./
RUN yarn install --production=false --pure-lockfile && yarn cache clean
COPY . .
RUN yarn build

# STAGE 3: FINAL
FROM base
WORKDIR /usr/src/wpp-server/

# Chromium já instalado no base
COPY . .
COPY --from=build /usr/src/wpp-server/ /usr/src/wpp-server/

# Porta padrão para Render: pegue da env ou use 21465 por padrão
ENV PORT=21465
ENV CHROME_PATH=/usr/bin/chromium
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Adiciona chromium no PATH (caso precise)
ENV PATH="/usr/bin:${PATH}"

# Expõe a porta (Render faz port binding automático, mas isso ajuda a documentar)
EXPOSE 21465

# Start do servidor: use a env PORT, se existir
CMD ["sh", "-c", "node dist/server.js --port ${PORT}"]