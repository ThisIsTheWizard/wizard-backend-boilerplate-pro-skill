# Prisma — Reference

**Ecosystems:** Node.js / TypeScript (NestJS, Fastify, Hono, Express-TS variants)
**Databases:** PostgreSQL, MySQL, SQLite, MongoDB
**Used by default:** NestJS boilerplate (all DB types)

> The **Express** boilerplate uses **Sequelize** (not Prisma) for SQL databases.
> See `references/databases/sequelize.md` for Express.

---

## Install

```bash
pnpm add @prisma/client
pnpm add -D prisma

# Initialize
pnpm prisma init --datasource-provider postgresql  # or mysql | sqlite | mongodb
```

---

## Full schema — NestJS boilerplate (PostgreSQL)

```prisma
generator client {
  binaryTargets = ["native", "linux-arm64-openssl-1.1.x", "linux-arm64-openssl-3.0.x"]
  provider      = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id            String     @id @default(uuid())
  created_at    DateTime   @default(now())
  created_by    String?
  email         String     @unique
  first_name    String?
  last_name     String?
  new_email     String?
  old_passwords String[]   @default([])
  password      String?
  phone_number  String?
  status        UserStatus @default(unverified)
  updated_at    DateTime   @updatedAt

  auth_tokens         AuthToken[]
  created_permissions Permission[]      @relation("CreatedBy")
  created_roles       Role[]            @relation("CreatedBy")
  role_permissions    RolePermission[]  @relation("CreatedBy")
  role_users          RoleUser[]
  verification_tokens VerificationToken[]

  @@map("users")
}

enum UserStatus {
  active
  inactive
  invited
  unverified
}

model Role {
  id         String   @id @default(uuid())
  created_at DateTime @default(now())
  created_by String?
  name       RoleName @unique
  updated_at DateTime @updatedAt

  creator          User?            @relation("CreatedBy", fields: [created_by], references: [id])
  role_permissions RolePermission[]
  role_users       RoleUser[]

  @@map("roles")
}

enum RoleName {
  admin
  developer
  moderator
  user
}

model Permission {
  id         String           @id @default(uuid())
  action     PermissionAction
  created_at DateTime         @default(now())
  created_by String?
  module     PermissionModule
  updated_at DateTime         @updatedAt

  creator          User?            @relation("CreatedBy", fields: [created_by], references: [id])
  role_permissions RolePermission[]

  @@unique([action, module])
  @@map("permissions")
}

enum PermissionAction {
  create
  read
  update
  delete
}

enum PermissionModule {
  permission
  role
  role_permission
  role_user
  user
}

model RoleUser {
  id      String @id @default(uuid())
  role_id String
  user_id String

  role Role @relation(fields: [role_id], references: [id], onDelete: Cascade)
  user User @relation(fields: [user_id], references: [id], onDelete: Cascade)

  @@unique([user_id, role_id])
  @@map("role_users")
}

model RolePermission {
  id                String   @id @default(uuid())
  can_do_the_action Boolean  @default(false)
  created_at        DateTime @default(now())
  created_by        String?
  permission_id     String
  role_id           String
  updated_at        DateTime @updatedAt

  creator    User?      @relation("CreatedBy", fields: [created_by], references: [id])
  permission Permission @relation(fields: [permission_id], references: [id], onDelete: Cascade)
  role       Role       @relation(fields: [role_id], references: [id], onDelete: Cascade)

  @@unique([role_id, permission_id])
  @@map("role_permissions")
}

model AuthToken {
  id            String   @id @default(uuid())
  created_at    DateTime @default(now())
  access_token  String   @unique
  refresh_token String   @unique
  updated_at    DateTime @updatedAt
  user_id       String

  user User @relation(fields: [user_id], references: [id], onDelete: Cascade)

  @@map("auth_tokens")
}

model VerificationToken {
  id         String      @id @default(uuid())
  created_at DateTime    @default(now())
  email      String
  expired_at DateTime
  status     TokenStatus @default(unverified)
  token      String      @unique
  type       TokenType
  updated_at DateTime    @updatedAt
  user_id    String

  user User @relation(fields: [user_id], references: [id], onDelete: Cascade)

  @@map("verification_tokens")
}

enum TokenType {
  user_verification
  forgot_password
}

enum TokenStatus {
  unverified
  verified
  cancelled
}

model AuthTemplate {
  id         String   @id @default(uuid())
  body       String
  created_at DateTime @default(now())
  event      String   @unique
  subject    String
  updated_at DateTime @updatedAt

  @@map("auth_templates")
}
```

---

## Schema for MongoDB (NestJS + Mongo)

Change the datasource provider to `mongodb`. All model fields remain the same,
but replace `@unique` array indexes with `@@index` and replace `@@unique([a, b])` with
`@@index([a, b])` (MongoDB does not support all PostgreSQL constraint syntax).

```prisma
datasource db {
  provider = "mongodb"
  url      = env("MONGODB_URL")
}
```

Prisma generates MongoDB-compatible client automatically.

---

## Seed file (`prisma/seed.ts`)

```typescript
import { Permission, PermissionAction, PermissionModule, PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
  const roles = await Promise.all(
    (['admin', 'user', 'moderator', 'developer'] as const).map((name) =>
      prisma.role.upsert({ where: { name }, update: { name }, create: { name } }),
    ),
  )

  const modules: PermissionModule[] = ['user', 'role', 'permission', 'role_user', 'role_permission']
  const actions: PermissionAction[] = ['create', 'read', 'update', 'delete']

  const permissions: Permission[] = []
  for (const module of modules) {
    for (const action of actions) {
      const permission = await prisma.permission.upsert({
        where: { action_module: { action, module } },
        update: { action, module },
        create: { action, module },
      })
      permissions.push(permission)
    }
  }

  const rolePermissions: Record<string, { permission_id: string; can_do_the_action: boolean }[]> = {
    admin:     permissions.map((p) => ({ permission_id: p.id, can_do_the_action: true })),
    moderator: permissions
      .filter((p) => (['read', 'update'].includes(p.action) && p.module === 'user') || (p.action === 'read'))
      .map((p) => ({ permission_id: p.id, can_do_the_action: true })),
    developer: permissions
      .filter((p) => p.action === 'read')
      .map((p) => ({ permission_id: p.id, can_do_the_action: true })),
    user: permissions
      .filter((p) => p.module === 'user' && p.action === 'read')
      .map((p) => ({ permission_id: p.id, can_do_the_action: true })),
  }

  for (const [role_name, rolePerms] of Object.entries(rolePermissions)) {
    const role = roles.find((r) => r.name === role_name)!
    for (const { permission_id, can_do_the_action } of rolePerms) {
      await prisma.rolePermission.upsert({
        where: { role_id_permission_id: { permission_id, role_id: role.id } },
        update: { can_do_the_action },
        create: { can_do_the_action, permission_id, role_id: role.id },
      })
    }
  }
}

main().catch(console.error).finally(() => prisma.$disconnect())
```

---

## PrismaService (NestJS)

```typescript
// src/prisma/prisma.service.ts
import { Injectable, OnModuleInit } from '@nestjs/common'
import { PrismaClient } from '@prisma/client'

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  async onModuleInit() {
    await this.$connect()
  }
}
```

Inject `PrismaService` into any NestJS service: `constructor(private prisma: PrismaService) {}`

---

## Common commands

```bash
pnpm prisma generate         # regenerate Prisma Client after schema changes
pnpm prisma migrate dev      # create + apply migration (dev)
pnpm prisma migrate deploy   # apply pending migrations (CI / prod)
pnpm prisma db push          # push schema without migration file (prototyping)
pnpm prisma studio           # visual DB browser at localhost:5555
pnpm prisma db seed          # run prisma/seed.ts
```

---

## Querying patterns

```typescript
// Paginated list with roles
const [data, total] = await Promise.all([
  this.prisma.user.findMany({
    skip:    (page - 1) * pageSize,
    take:    pageSize,
    orderBy: { created_at: 'desc' },
    include: { role_users: { include: { role: true } } },
  }),
  this.prisma.user.count(),
])

// Upsert (used in seed)
await this.prisma.role.upsert({
  where:  { name: 'admin' },
  update: { name: 'admin' },
  create: { name: 'admin' },
})

// Transaction
await this.prisma.$transaction([
  this.prisma.user.update({ where: { id }, data: { status: 'active' } }),
  this.prisma.verificationToken.updateMany({ where: { user_id: id }, data: { status: 'verified' } }),
])
```
