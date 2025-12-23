# ---------- base deps ----------
FROM node:20-alpine AS base
WORKDIR /repo

# Enable pnpm (via corepack)
RUN corepack enable && corepack prepare pnpm@10.9.0 --activate

# Copy workspace manifests first (better caching)
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml turbo.json ./

# Copy each package.json so pnpm can compute workspace graph
COPY apps/web/package.json apps/web/package.json
COPY apps/api/package.json apps/api/package.json
COPY packages/ui/package.json packages/ui/package.json
COPY packages/utils/package.json packages/utils/package.json

# Install workspace dependencies
RUN pnpm install --frozen-lockfile


# ---------- build ----------
FROM base AS build
WORKDIR /repo

# Copy full repo
COPY . .

# Build everything (turbo)
RUN pnpm build

# Create production deploy folder for API (includes node_modules + workspace deps)
# pnpm v10 requires inject-workspace-packages OR legacy deploy, so we use --legacy
RUN pnpm --filter @apps/api deploy --prod --legacy /deploy/api


# ---------- API runtime ----------
FROM node:20-alpine AS api
WORKDIR /app
ENV NODE_ENV=production

# Copy deployed API app (dist + node_modules + package.json)
COPY --from=build /deploy/api ./

EXPOSE 3001
CMD ["node", "dist/index.js"]


# ---------- WEB runtime (Next standalone) ----------
FROM node:20-alpine AS web
WORKDIR /app
ENV NODE_ENV=production

# In monorepos, standalone output contains apps/web/server.js
COPY --from=build /repo/apps/web/.next/standalone ./

# Static + public must be placed under the same nested path
COPY --from=build /repo/apps/web/.next/static ./apps/web/.next/static
COPY --from=build /repo/apps/web/public ./apps/web/public

EXPOSE 3000
CMD ["node", "apps/web/server.js"]
