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

# Create a production deploy folder for the API (includes node_modules)
RUN pnpm --filter @apps/api deploy --prod /deploy/api


# ---------- API runtime ----------
FROM node:20-alpine AS api
WORKDIR /app
ENV NODE_ENV=production

# Copy the deployed prod folder (contains dist + node_modules)
COPY --from=build /deploy/api ./

EXPOSE 3001
CMD ["node", "dist/index.js"]


# ---------- WEB runtime (Next standalone) ----------
FROM node:20-alpine AS web
WORKDIR /app
ENV NODE_ENV=production

# standalone output includes apps/web/server.js in monorepos
COPY --from=build /repo/apps/web/.next/standalone ./
COPY --from=build /repo/apps/web/.next/static ./apps/web/.next/static
COPY --from=build /repo/apps/web/public ./apps/web/public

EXPOSE 3000
CMD ["node", "apps/web/server.js"]
