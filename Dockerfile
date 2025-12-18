# ---------- base deps ----------
FROM node:20-alpine AS base
WORKDIR /repo

# pnpm
RUN corepack enable && corepack prepare pnpm@10.9.0 --activate

# Copy workspace manifests first (better caching)
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml turbo.json ./
COPY apps/web/package.json apps/web/package.json
COPY apps/api/package.json apps/api/package.json
COPY packages/ui/package.json packages/ui/package.json
COPY packages/utils/package.json packages/utils/package.json

# Install deps (workspace)
RUN pnpm install --frozen-lockfile


# ---------- build ----------
FROM base AS build
WORKDIR /repo

# Copy the rest of the source
COPY . .

# Build all (turbo)
RUN pnpm build


# ---------- API runtime ----------
FROM node:20-alpine AS api
WORKDIR /app
ENV NODE_ENV=production

# Copy only what api needs at runtime
COPY --from=build /repo/apps/api/dist ./dist
COPY --from=build /repo/apps/api/package.json ./package.json

# If API has runtime deps (express), we need node_modules for api
# easiest: install prod deps just for api
RUN corepack enable && corepack prepare pnpm@10.9.0 --activate \
  && pnpm install --prod

EXPOSE 3001
CMD ["node", "dist/index.js"]


# ---------- WEB runtime (Next standalone) ----------
FROM node:20-alpine AS web
WORKDIR /app
ENV NODE_ENV=production

# Next standalone output includes server.js + minimal node_modules
COPY --from=build /repo/apps/web/.next/standalone ./
COPY --from=build /repo/apps/web/.next/static ./.next/static
COPY --from=build /repo/apps/web/public ./public

EXPOSE 3000
CMD ["node", "server.js"]
