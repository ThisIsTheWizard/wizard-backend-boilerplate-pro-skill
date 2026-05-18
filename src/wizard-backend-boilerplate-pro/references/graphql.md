# GraphQL Reference

Per-framework setup guide for the `GraphQLServer` module. Applied only when `GRAPHQL = yes`.

The GraphQL endpoint runs alongside the existing REST API. REST routes are not replaced.

---

## Package resolution

| Framework | Package(s) | Playground UI |
|---|---|---|
| Express | `@apollo/server` `@as-integrations/express5` | Apollo Sandbox at `/graphql` |
| Fastify | `mercurius` `mercurius-codegen` | GraphiQL at `/graphiql` |
| NestJS | `@nestjs/graphql` `@apollo/server` `graphql` | Apollo Sandbox at `/graphql` |
| Hono | `@hono/graphql-server` `graphql` | GraphiQL via `graphiqlPath` |
| FastAPI | `strawberry-graphql[fastapi]` | GraphiQL at `/graphql` |
| Django | `strawberry-graphql[django]` | GraphiQL at `/graphql/` |
| Flask | `strawberry-graphql[flask]` | GraphiQL at `/graphql` |
| Gin | `99designs/gqlgen` | Playground at `/playground` |
| Echo | `99designs/gqlgen` | Playground at `/playground` |

---

## Express

### Install

```bash
$PM add @apollo/server @as-integrations/express5 graphql
```

### File: `src/graphql/schema.ts`

Copy from `assets/api-templates/express/graphql/schema.ts.template`.

### Wire into `src/app.ts`

```typescript
import { ApolloServer } from '@apollo/server';
import { expressMiddleware } from '@as-integrations/express5';
import { typeDefs, resolvers } from './graphql/schema';

const apolloServer = new ApolloServer({ typeDefs, resolvers });
await apolloServer.start();

app.use('/graphql', express.json(), expressMiddleware(apolloServer, {
  context: async ({ req }) => ({ user: (req as any).user }),
}));
```

### Endpoint

| Method | Path | Notes |
|---|---|---|
| `POST` | `/graphql` | Execute queries and mutations |
| `GET` | `/graphql` | Apollo Sandbox (development only) |

---

## Fastify

### Install

```bash
$PM add mercurius graphql
```

### Wire into server

```typescript
import mercurius from 'mercurius';
import { typeDefs, resolvers } from './graphql/schema';

await app.register(mercurius, {
  schema: typeDefs,
  resolvers,
  graphiql: true,           // /graphiql in dev
});
```

### File: `src/graphql/schema.ts` — same SDL typeDefs + resolvers pattern.

---

## NestJS

### Install

```bash
$PM add @nestjs/graphql @apollo/server graphql
```

### `src/graphql/graphql.module.ts`

```typescript
import { Module } from '@nestjs/common';
import { GraphQLModule } from '@nestjs/graphql';
import { ApolloDriver, ApolloDriverConfig } from '@nestjs/apollo';
import { UsersResolver } from './users.resolver';
import { BlogResolver } from './blog.resolver';

@Module({
  imports: [
    GraphQLModule.forRoot<ApolloDriverConfig>({
      driver: ApolloDriver,
      autoSchemaFile: true,
      playground: process.env.NODE_ENV !== 'production',
    }),
  ],
  providers: [UsersResolver, BlogResolver],
})
export class GraphqlModule {}
```

Import `GraphqlModule` in `AppModule`.

---

## Hono

### Install

```bash
$PM add @hono/graphql-server graphql
```

### Wire into `src/index.ts`

```typescript
import { graphqlServer } from '@hono/graphql-server';
import { schema } from './graphql/schema';

app.use('/graphql', graphqlServer({ schema }));
```

---

## FastAPI

### Install

```bash
pip install strawberry-graphql[fastapi]
```

### File: `app/graphql/schema.py`

```python
import strawberry
from strawberry.fastapi import GraphQLRouter

@strawberry.type
class Query:
    @strawberry.field
    def health(self) -> str:
        return "ok"

schema = strawberry.Schema(query=Query)
graphql_app = GraphQLRouter(schema)
```

### Wire into `app/main.py`

```python
from app.graphql.schema import graphql_app

app.include_router(graphql_app, prefix="/graphql")
```

---

## Django

### Install

```bash
pip install strawberry-graphql[django]
```

### `config/urls.py`

```python
from strawberry.django.views import AsyncGraphQLView
from myapp.graphql.schema import schema

urlpatterns += [
    path("graphql/", AsyncGraphQLView.as_view(schema=schema)),
]
```

### File: `myapp/graphql/schema.py` — define `@strawberry.type Query` with resolvers.

---

## Flask

### Install

```bash
pip install strawberry-graphql[flask]
```

### Wire into `app/__init__.py`

```python
from strawberry.flask.views import GraphQLView
from app.graphql.schema import schema

app.add_url_rule("/graphql", view_func=GraphQLView.as_view("graphql_view", schema=schema))
```

---

## Gin

### Install

```bash
go get github.com/99designs/gqlgen
go run github.com/99designs/gqlgen init
```

### Wire into `cmd/server/main.go`

```go
import "github.com/99designs/gqlgen/graphql/handler"
import "github.com/99designs/gqlgen/graphql/playground"

srv := handler.NewDefaultServer(generated.NewExecutableSchema(generated.Config{
    Resolvers: &graph.Resolver{DB: db},
}))

r.POST("/graphql", gin.WrapH(srv))
r.GET("/playground", gin.WrapH(playground.Handler("GraphQL Playground", "/graphql")))
```

---

## Echo

### Install

```bash
go get github.com/99designs/gqlgen
go run github.com/99designs/gqlgen init
```

### Wire into `cmd/server/main.go`

```go
import "github.com/99designs/gqlgen/graphql/handler"
import "github.com/99designs/gqlgen/graphql/playground"

srv := handler.NewDefaultServer(generated.NewExecutableSchema(generated.Config{
    Resolvers: &graph.Resolver{DB: db},
}))

e.POST("/graphql", echo.WrapHandler(srv))
e.GET("/playground", echo.WrapHandler(playground.Handler("GraphQL Playground", "/graphql")))
```

---

## GraphQL schema — shared SDL (Node.js / Express / Fastify / Hono)

All Node.js frameworks use the same SDL type definitions and resolver map.
Copy from `assets/api-templates/express/graphql/schema.ts.template`.

The schema exposes:
- `Query.users` — paginated user list (mirrors `GET /users`)
- `Query.user(id)` — single user (mirrors `GET /users/:id`)
- `Query.posts` — paginated blog post list (mirrors `GET /blog/posts`)
- `Query.post(id)` — single post (mirrors `GET /blog/posts/:id`)
- `Mutation.createPost` — create blog post (mirrors `POST /blog/posts`)
- `Mutation.updatePost` — update blog post (mirrors `PUT /blog/posts/:id`)
- `Mutation.deletePost` — delete blog post (mirrors `DELETE /blog/posts/:id`)
- `Mutation.publishPost` — publish a draft post (mirrors `PATCH /blog/posts/:id/publish`)

---

## Notes

- The GraphQL context receives the authenticated `user` object from the auth middleware so resolvers can enforce authorization identically to REST routes.
- In production (`NODE_ENV=production`), disable the playground / GraphiQL UI.
- The GraphQL endpoint is excluded from the default rate-limiter route list; apply a separate, stricter limiter if needed (GraphQL queries can be expensive).
