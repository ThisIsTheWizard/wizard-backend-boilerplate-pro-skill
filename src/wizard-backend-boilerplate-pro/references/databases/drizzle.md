# Drizzle ORM — Reference

**Ecosystems:** Node.js / TypeScript (best fit for Hono; also works with Express/Fastify)
**Databases:** PostgreSQL, MySQL, SQLite, Turso
**Docs:** https://orm.drizzle.team

## Install

```bash
# PostgreSQL
$PM add drizzle-orm postgres
$PM add -D drizzle-kit @types/pg

# MySQL
$PM add drizzle-orm mysql2
$PM add -D drizzle-kit

# SQLite
$PM add drizzle-orm better-sqlite3
$PM add -D drizzle-kit @types/better-sqlite3
```

## drizzle.config.ts

```typescript
import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  schema: './src/db/schema.ts',
  out: './drizzle',
  dialect: 'postgresql', // 'mysql' | 'sqlite'
  dbCredentials: { url: process.env.DATABASE_URL! },
});
```

## src/db/schema.ts

```typescript
import {
  pgTable, text, timestamp, boolean, uuid, index
} from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  id: uuid('id').defaultRandom().primaryKey(),
  email: text('email').unique().notNull(),
  password: text('password').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull().$onUpdateFn(() => new Date()),
}, (t) => [index('idx_users_email').on(t.email)]);

export const apiKeys = pgTable('api_keys', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
  hashedKey: text('hashed_key').unique().notNull(),
  isActive: boolean('is_active').default(true).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// Type exports
export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
```

## Client setup (src/db/client.ts)

```typescript
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from './schema';

const queryClient = postgres(process.env.DATABASE_URL!);
export const db = drizzle(queryClient, { schema });
```

## Common commands

```bash
npx drizzle-kit generate    # generate migration files from schema
npx drizzle-kit migrate     # apply pending migrations
npx drizzle-kit push        # push schema directly (prototyping, no migration file)
npx drizzle-kit studio      # open Drizzle Studio on localhost:4983
```

## Querying patterns

```typescript
import { db } from '../db/client';
import { users } from '../db/schema';
import { eq, ilike, desc, count, and } from 'drizzle-orm';

// Find many with pagination + search
const result = await db
  .select({ id: users.id, email: users.email, createdAt: users.createdAt })
  .from(users)
  .where(search ? ilike(users.email, `%${search}%`) : undefined)
  .orderBy(desc(users.createdAt))
  .limit(pageSize)
  .offset((page - 1) * pageSize);

// Count total
const [{ total }] = await db.select({ total: count() }).from(users);

// Insert
const [user] = await db.insert(users).values({ email, password: hashed }).returning();

// Update
await db.update(users).set({ updatedAt: new Date() }).where(eq(users.id, id));

// Delete
await db.delete(users).where(eq(users.id, id));

// Transaction
await db.transaction(async (tx) => {
  const [user] = await tx.insert(users).values({ email, password }).returning();
  await tx.insert(apiKeys).values({ userId: user.id, hashedKey });
});
```

## SQLite setup (for local dev)

```typescript
import { drizzle } from 'drizzle-orm/better-sqlite3';
import Database from 'better-sqlite3';
import * as schema from './schema';

const sqlite = new Database(process.env.DB_PATH ?? './dev.db');
export const db = drizzle(sqlite, { schema });
```

## Why Drizzle for Hono?

Drizzle is the natural ORM for Hono because:
- Both are lightweight and edge-compatible
- Drizzle's query builder runs in any JS runtime (Workers, Bun, Node)
- Drizzle-kit migrations are SQL files you can inspect and version
- TypeScript inference is first-class with no codegen CLI required (schema is just TS)
