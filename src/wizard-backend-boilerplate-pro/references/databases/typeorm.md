# TypeORM — Reference

**Ecosystems:** Node.js / TypeScript (default ORM for NestJS)
**Databases:** PostgreSQL, MySQL, SQLite, MongoDB, Oracle, MS SQL
**Docs:** https://typeorm.io

## Install

```bash
# Core + PostgreSQL
$PM add typeorm @nestjs/typeorm pg reflect-metadata
$PM add -D @types/pg

# MySQL instead of PostgreSQL
$PM add typeorm @nestjs/typeorm mysql2

# SQLite
$PM add typeorm @nestjs/typeorm better-sqlite3
$PM add -D @types/better-sqlite3
```

Add to `tsconfig.json`:
```json
{
  "compilerOptions": {
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true
  }
}
```

## Entity definition

```typescript
// src/users/user.entity.ts
import {
  Entity, PrimaryGeneratedColumn, Column,
  CreateDateColumn, UpdateDateColumn, Index
} from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ unique: true })
  email: string;

  @Column()
  password: string;

  @Column({ default: true })
  isActive: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
```

## DataSource setup (standalone Express/Fastify)

```typescript
// src/lib/data-source.ts
import { DataSource } from 'typeorm';
import { User } from '../users/user.entity';

export const AppDataSource = new DataSource({
  type: 'postgres',
  url: process.env.DATABASE_URL,
  entities: [User],
  migrations: ['src/migrations/*.ts'],
  synchronize: process.env.NODE_ENV === 'development', // never in prod
  logging: process.env.NODE_ENV === 'development',
});

// Initialize in server.ts
await AppDataSource.initialize();
```

## NestJS TypeORM module (recommended)

```typescript
// app.module.ts
import { TypeOrmModule } from '@nestjs/typeorm';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        url: config.get('DATABASE_URL'),
        entities: [__dirname + '/**/*.entity{.ts,.js}'],
        migrations: [__dirname + '/migrations/*{.ts,.js}'],
        synchronize: config.get('NODE_ENV') === 'development',
      }),
    }),
  ],
})
export class AppModule {}

// Feature module registers specific entities
@Module({
  imports: [TypeOrmModule.forFeature([User])],
  providers: [UsersService],
})
export class UsersModule {}
```

## Repository pattern (NestJS)

```typescript
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Like } from 'typeorm';
import { User } from './user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepo: Repository<User>,
  ) {}

  findAll(page = 1, limit = 20, search?: string) {
    return this.usersRepo.findAndCount({
      where: search ? { email: Like(`%${search}%`) } : {},
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
      select: ['id', 'email', 'createdAt'],
    });
  }

  create(email: string, password: string) {
    const user = this.usersRepo.create({ email, password });
    return this.usersRepo.save(user);
  }
}
```

## Migration CLI commands

```bash
# Generate migration from entity changes
npx typeorm migration:generate src/migrations/AddUserTable -d src/lib/data-source.ts

# Run migrations
npx typeorm migration:run -d src/lib/data-source.ts

# Revert last migration
npx typeorm migration:revert -d src/lib/data-source.ts
```

## Connection strings

```env
# PostgreSQL
DATABASE_URL=postgresql://user:password@localhost:5432/dbname

# MySQL
DATABASE_URL=mysql://user:password@localhost:3306/dbname

# SQLite
DATABASE_URL=sqlite://./dev.db
```

## Key differences from Prisma

| Feature | TypeORM | Prisma |
|---|---|---|
| Schema definition | TypeScript decorators on classes | `.prisma` DSL file |
| Query API | Repository + QueryBuilder | Prisma Client (typed methods) |
| Code generation | None needed | `prisma generate` |
| NestJS integration | First-class (`@nestjs/typeorm`) | Via PrismaService |
| Synchronize option | `synchronize: true` (dev only) | `db push` |
