# NestJS — Reference

**Language:** TypeScript
**Version:** 11.x (`@nestjs/core@latest`)
**ORM:** Prisma (both Postgres and MongoDB)
**Test framework:** Jest
**Package manager:** pnpm (preferred)

---

## Directory structure

```
<APP_NAME>/
├── src/
│   ├── main.ts                         # Bootstrap (CORS, ValidationPipe, listen)
│   ├── app/
│   │   ├── app.module.ts               # Root module — imports all feature modules
│   │   ├── app.controller.ts           # GET / welcome route
│   │   └── app.service.ts
│   ├── auth/
│   │   ├── auth.module.ts
│   │   ├── auth.service.ts
│   │   ├── auth.controller.ts          # REST: register, login, refresh, etc.
│   │   ├── auth.dto.ts                 # CreateUserDto, LoginDto, etc.
│   │   └── auth.interface.ts           # RequestUser interface
│   ├── user/
│   │   ├── user.module.ts
│   │   ├── user.service.ts
│   │   ├── user.controller.ts
│   │   ├── user.dto.ts
│   │   └── user.interface.ts
│   ├── role/
│   │   ├── role.module.ts
│   │   ├── role.service.ts
│   │   ├── role.controller.ts
│   │   └── role.dto.ts
│   ├── permission/
│   │   ├── permission.module.ts
│   │   ├── permission.service.ts
│   │   ├── permission.controller.ts
│   │   └── permission.dto.ts
│   ├── auth-token/
│   │   ├── auth-token.service.ts
│   │   ├── auth-token.dto.ts
│   │   └── auth-token.interface.ts
│   ├── verification-token/
│   │   └── verification-token.service.ts
│   ├── common/
│   │   ├── common.module.ts
│   │   ├── common.service.ts           # bcrypt, JWT, validation helpers
│   │   └── common.interface.ts
│   ├── prisma/
│   │   └── prisma.service.ts
│   ├── guards/
│   │   ├── auth.guard.ts               # JWT validation + user lookup
│   │   ├── roles.guard.ts              # Role check via @Roles() decorator
│   │   └── permissions.guard.ts        # Permission check via @Permissions()
│   ├── decorators/
│   │   ├── user.decorator.ts           # @CurrentUser() param decorator
│   │   ├── roles.decorator.ts          # @Roles(...roles)
│   │   ├── permissions.decorator.ts    # @Permissions(...permissions)
│   │   └── password.decorator.ts       # @IsPassword() validator
│   └── filters/
│       └── global-exception.filter.ts
├── prisma/
│   ├── schema.prisma
│   └── seed.ts
├── test/
│   ├── setup.ts
│   ├── fixtures.ts
│   └── <module>.test.ts
├── .env
├── .env.sample
├── .env.test
├── .gitignore
├── .dockerignore
├── tsconfig.json
├── tsconfig.build.json
├── nest-cli.json
├── jest.config.js
├── prettier.config.js
├── eslint.config.mjs
├── package.json
├── Dockerfile.Dev
├── Dockerfile.Prod
├── Dockerfile.Test
├── docker-compose.dev.yml
├── docker-compose.prod.yml
└── docker-compose.test.yml
```

---

## Init commands

```bash
mkdir "$APP_NAME" && cd "$APP_NAME"

# Scaffold via NestJS CLI
npm i -g pnpm @nestjs/cli
nest new "$APP_NAME" --package-manager pnpm --language TypeScript
cd "$APP_NAME"

# Core dependencies
pnpm add @nestjs/config @nestjs/platform-express
pnpm add @prisma/client bcryptjs jsonwebtoken validator axios lodash \
         class-validator class-transformer cors dotenv \
         @aws-sdk/client-ses reflect-metadata rxjs

pnpm add -D prisma typescript ts-node ts-jest jest @types/jest \
           @types/node @types/jsonwebtoken @types/bcryptjs @types/cors \
           @types/lodash @types/validator @nestjs/cli @nestjs/testing \
           prettier eslint typescript-eslint eslint-config-prettier \
           eslint-plugin-prettier eslint-plugin-import globals \
           prettier-plugin-organize-imports

pnpm prisma init --datasource-provider postgresql
```

---

## package.json scripts

```json
{
  "scripts": {
    "compose:dev-down":  "docker compose -f docker-compose.dev.yml down -v",
    "compose:dev-up":    "docker compose -f docker-compose.dev.yml up -d --build",
    "compose:prod-down": "docker compose -f docker-compose.prod.yml down -v",
    "compose:prod-up":   "docker compose -f docker-compose.prod.yml up -d --build",
    "compose:test-down": "docker compose -f docker-compose.test.yml down -v --remove-orphans",
    "compose:test-up":   "docker compose -f docker-compose.test.yml up --build --abort-on-container-exit --exit-code-from test_runner test_runner",
    "db:generate": "prisma generate",
    "db:push":     "prisma db push",
    "db:migrate":  "prisma migrate dev",
    "db:studio":   "prisma studio",
    "db:seed":     "ts-node prisma/seed.ts",
    "dev":         "pnpm compose:dev-down && pnpm compose:dev-up",
    "format":      "prettier --write \"src/**/*.ts\" \"test/**/*.ts\"",
    "lint":        "eslint \"{src,apps,libs,test}/**/*.ts\"",
    "lint-fix":    "eslint \"{src,apps,libs,test}/**/*.ts\" --fix",
    "nest:build":  "nest build",
    "nest:dev":    "nest start --watch",
    "nest:start":  "nest start",
    "seed":        "pnpm db:seed",
    "test":        "pnpm compose:test-down && pnpm compose:test-up"
  }
}
```

---

## tsconfig.json

```json
{
  "compilerOptions": {
    "module": "nodenext",
    "moduleResolution": "nodenext",
    "resolvePackageJsonExports": true,
    "esModuleInterop": true,
    "isolatedModules": true,
    "declaration": true,
    "removeComments": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "allowSyntheticDefaultImports": true,
    "target": "ES2023",
    "sourceMap": true,
    "outDir": "./build",
    "baseUrl": "./",
    "paths": { "@/*": ["src/*"] },
    "incremental": true,
    "skipLibCheck": true,
    "strictNullChecks": true,
    "noImplicitAny": false
  }
}
```

---

## src/main.ts

```typescript
import { BadRequestException, ValidationPipe } from '@nestjs/common'
import { NestFactory } from '@nestjs/core'
import 'dotenv/config'
import { AppModule } from '@/app/app.module'

async function bootstrap() {
  const app = await NestFactory.create(AppModule)

  app.enableCors({ origin: '*' })

  app.useGlobalPipes(
    new ValidationPipe({
      exceptionFactory: (errors) => {
        const messages = errors
          .flatMap((e) => (e.constraints ? Object.values(e.constraints) : []))
          .map((msg) => msg.toUpperCase().replace(/\s+/g, '_'))
        return new BadRequestException({ messages, success: false })
      },
      forbidNonWhitelisted: true,
      transform: true,
      whitelist: true,
    }),
  )

  await app.listen(process.env.PORT ?? 8000)
  console.log(`====> Server running on http://localhost:${process.env.PORT ?? 8000} <====`)
}

bootstrap()
```

---

## src/app/app.module.ts

```typescript
import { Module } from '@nestjs/common'
import { ConfigModule } from '@nestjs/config'
import { AppController } from '@/app/app.controller'
import { AppService } from '@/app/app.service'
import { AuthModule } from '@/auth/auth.module'
import { CommonService } from '@/common/common.service'
import { PermissionModule } from '@/permission/permission.module'
import { PrismaService } from '@/prisma/prisma.service'
import { RoleModule } from '@/role/role.module'
import { UserModule } from '@/user/user.module'

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    AuthModule,
    UserModule,
    RoleModule,
    PermissionModule,
  ],
  controllers: [AppController],
  providers: [AppService, PrismaService, CommonService],
})
export class AppModule {}
```

---

## src/prisma/prisma.service.ts

```typescript
import { Injectable, OnModuleInit } from '@nestjs/common'
import { PrismaClient } from '@prisma/client'

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  async onModuleInit() {
    await this.$connect()
  }
}
```

---

## src/common/common.service.ts

```typescript
import { Injectable } from '@nestjs/common'
import { ConfigService } from '@nestjs/config'
import * as bcrypt from 'bcryptjs'
import * as jwt from 'jsonwebtoken'
import { isEmail, isStrongPassword } from 'validator'

@Injectable()
export class CommonService {
  constructor(private configService: ConfigService) {}

  async comparePassword(password: string, hash: string): Promise<boolean> {
    return bcrypt.compare(password, hash)
  }

  async hashPassword(password: string): Promise<string> {
    const rounds = parseInt(this.configService.get<string>('BCRYPT_ROUNDS', '10'), 10)
    return bcrypt.hash(password, rounds)
  }

  generateJWTToken(payload: object, isRefreshToken = false): string {
    const secret = this.configService.get<string>('JWT_SECRET', '')
    const expiresIn = isRefreshToken
      ? this.configService.get<string>('REFRESH_TOKEN_EXPIRY', '7d')
      : this.configService.get<string>('ACCESS_TOKEN_EXPIRY', '1d')
    return jwt.sign(payload, secret, { expiresIn, issuer: this.configService.get('JWT_ISSUER') })
  }

  verifyJWTToken(token: string): jwt.JwtPayload | string {
    return jwt.verify(token, this.configService.get<string>('JWT_SECRET', ''))
  }

  decodeJWTToken(token: string): jwt.JwtPayload | string | null {
    return jwt.decode(token)
  }

  validateEmail(email: string): boolean { return isEmail(email) }

  validatePassword(password: string): boolean {
    return isStrongPassword(password, { minLength: 8, minLowercase: 1, minUppercase: 1, minNumbers: 1, minSymbols: 1 })
  }
}
```

---

## src/guards/auth.guard.ts

```typescript
import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common'
import { RoleName } from '@prisma/client'
import { CommonService } from '@/common/common.service'
import { PrismaService } from '@/prisma/prisma.service'

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private commonService: CommonService, private prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest()
    const token = request.headers.authorization?.replace('Bearer ', '')
    if (!token) throw new UnauthorizedException('UNAUTHORIZED')

    const decoded = this.commonService.verifyJWTToken(token) as { user_id?: string }
    if (!decoded?.user_id) throw new UnauthorizedException('UNAUTHORIZED')

    const user = await this.prisma.user.findUnique({
      where: { id: decoded.user_id },
      include: {
        role_users: {
          include: {
            role: { include: { role_permissions: { include: { permission: true } } } },
          },
        },
      },
    })
    if (!user?.id) throw new UnauthorizedException('UNAUTHORIZED')

    const roles = new Set<RoleName>()
    const permissions = new Set<string>()
    user.role_users.forEach((ru) => {
      roles.add(ru.role.name)
      ru.role.role_permissions?.forEach((rp) => {
        if (rp.can_do_the_action && rp.permission)
          permissions.add(`${rp.permission.module}.${rp.permission.action}`)
      })
    })

    request.user = { email: user.email, user_id: user.id, roles: [...roles], permissions: [...permissions] }
    return true
  }
}
```

---

## src/decorators/password.decorator.ts

```typescript
import { IsStrongPassword } from 'class-validator'

export const IsPassword = () =>
  IsStrongPassword({ minLength: 8, minLowercase: 1, minUppercase: 1, minNumbers: 1, minSymbols: 1 })
```

---

## src/decorators/user.decorator.ts

```typescript
import { createParamDecorator, ExecutionContext } from '@nestjs/common'

export const CurrentUser = createParamDecorator((data: string, ctx: ExecutionContext) => {
  const request = ctx.switchToHttp().getRequest()
  return data ? request.user?.[data] : request.user
})
```

---

## Feature module anatomy

Each feature (`user`, `role`, `permission`, etc.) follows this structure:

```typescript
// role.module.ts
@Module({
  providers: [RoleService, PrismaService, CommonService],
  controllers: [RoleController],
  exports: [RoleService],
})
export class RoleModule {}

// role.service.ts — wraps Prisma calls
@Injectable()
export class RoleService {
  constructor(private prisma: PrismaService) {}
  getRole(options: Prisma.RoleFindUniqueArgs) { return this.prisma.role.findUnique(options) }
  getRoles(options: Prisma.RoleFindManyArgs)  { return this.prisma.role.findMany(options) }
}

// role.controller.ts — thin HTTP layer
@Controller('roles')
export class RoleController {
  constructor(private roleService: RoleService) {}
  @Get()
  @UseGuards(AuthGuard, RolesGuard)
  @Roles('admin', 'developer')
  getRoles(@Query() query: GetRolesDto) { return this.roleService.getRoles({}) }
}
```

---

## GraphQL variant (Nest_GraphQL)

When `GRAPHQL = yes`, swap `app.module.ts` to include `GraphQLModule`:

```typescript
import { ApolloServerPluginLandingPageLocalDefault } from '@apollo/server/plugin/landingPage/default'
import { ApolloDriver, ApolloDriverConfig } from '@nestjs/apollo'
import { GraphQLModule } from '@nestjs/graphql'

GraphQLModule.forRoot<ApolloDriverConfig>({
  autoSchemaFile: true,
  context: ({ req }) => ({ req }),
  driver: ApolloDriver,
  introspection: true,
  playground: false,
  plugins: [ApolloServerPluginLandingPageLocalDefault()],
})
```

Install: `pnpm add @nestjs/graphql @apollo/server @as-integrations/express5 graphql`

Each module gains a resolver (`*.resolver.ts`) with `@Resolver()`, `@Query()`, `@Mutation()` decorators.
Guards are adapted to GraphQL context via `GqlExecutionContext.create(context)`.

---

## Docker (three environments)

### Dockerfile.Dev
```dockerfile
FROM node:22-alpine
RUN apk add --no-cache openssl
WORKDIR /app
COPY package.json .
RUN npm i -g pnpm && pnpm i
COPY . .
CMD ["sh", "-c", "pnpm db:generate && pnpm db:push && pnpm nest:dev"]
EXPOSE 8000
```

### Dockerfile.Prod
```dockerfile
FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json .
RUN npm install -g pnpm && pnpm i
COPY . .
RUN pnpm lint && pnpm db:generate && pnpm nest:build

FROM node:22-alpine AS runner
WORKDIR /app
RUN apk add --no-cache openssl
ENV NODE_ENV=production
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nestjs
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/build ./build
USER nestjs
EXPOSE 8000
CMD ["node", "build/main"]
```

### docker-compose.dev.yml
```yaml
services:
  postgres:
    image: postgres:17
    env_file: .env
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U postgres']
      interval: 5s
      retries: 5
    ports: ['5432:5432']
    volumes: [postgres_data:/var/lib/postgresql/data]
  pgadmin:
    image: dpage/pgadmin4
    env_file: .env
    ports: ['4000:80']
    depends_on: { postgres: { condition: service_healthy } }
  node_server:
    build: { context: ., dockerfile: Dockerfile.Dev }
    ports: ['8000:8000']
    env_file: .env
    depends_on: { postgres: { condition: service_healthy } }
    volumes: [.:/app, /app/node_modules]
volumes:
  postgres_data:
  pgadmin_data:
```

---

## Test setup

```typescript
// test/setup.ts
import { PrismaClient } from '@prisma/client'
import axios from 'axios'
import { config } from 'dotenv'
import path from 'path'

config({ path: path.resolve(__dirname, '..', '.env.test'), override: false })

export const api = axios.create({
  baseURL: `http://node_server_test:${process.env.PORT || 8000}`,
  timeout: 15000,
  validateStatus: () => true,
})

export const prisma = new PrismaClient({ datasources: { db: { url: process.env.DATABASE_URL } } })

export const resetDatabase = async () => {
  const response = await api.post('/test/setup')
  if (response.status >= 400) throw new Error(`Failed to reset database: ${response.status}`)
  return response.data
}

beforeAll(async () => { await prisma.$connect() })
afterAll(async () => { await prisma.$disconnect() })
```

---

## .env variables

```env
ACCESS_TOKEN_EXPIRY=1d
BCRYPT_ROUNDS=10
DATABASE_URL=postgres://postgres:postgres@postgres:5432/postgres
FROM_EMAIL=no-reply@example.com
JWT_ISSUER={{APP_NAME}}
JWT_SECRET=randomly_generated_secret_key
NODE_ENV=development
PORT=8000
REFRESH_TOKEN_EXPIRY=7d
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=postgres
PGADMIN_DEFAULT_EMAIL=postgres@postgres.com
PGADMIN_DEFAULT_PASSWORD=postgres
```
