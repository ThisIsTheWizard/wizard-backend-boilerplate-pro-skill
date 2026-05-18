# Express — Reference

**Language:** Node.js / JavaScript (Babel transpiled)
**Version:** 4.x (`express@latest` in the 4.x line)
**ORM:** Sequelize (Postgres/MySQL/SQLite) · Mongoose (MongoDB)
**Test framework:** Mocha + Chai

> The Express boilerplate uses **JavaScript with Babel** — not TypeScript.
> TypeScript types are not used; validation is done with `validator` library.

---

## Directory structure

```
<APP_NAME>/
├── src/
│   ├── server.js               # Entry point — connects DB, starts Express
│   ├── routes/
│   │   └── index.js            # Mounts all module routers
│   ├── middlewares/
│   │   ├── index.js            # Barrel: exports authorizer + error
│   │   ├── authorizer.js       # JWT validation + role/permission check
│   │   └── error.js            # Global error handler middleware
│   ├── modules/
│   │   ├── controllers.js      # Barrel: re-exports all controllers
│   │   ├── services.js         # Barrel: re-exports all services
│   │   ├── routers.js          # Barrel: re-exports all routers
│   │   ├── entities.js         # Barrel: re-exports all Sequelize entities
│   │   ├── helpers.js          # Barrel: re-exports all helpers
│   │   ├── user/
│   │   │   ├── user.entity.js
│   │   │   ├── user.service.js
│   │   │   ├── user.helper.js
│   │   │   ├── user.controller.js
│   │   │   └── user.router.js
│   │   ├── permission/
│   │   │   ├── permission.entity.js
│   │   │   ├── permission.service.js
│   │   │   ├── permission.helper.js
│   │   │   ├── permission.controller.js
│   │   │   └── permission.router.js
│   │   ├── role/
│   │   │   └── (same 5-file pattern)
│   │   ├── role-user/
│   │   │   └── (same 5-file pattern)
│   │   ├── role-permission/
│   │   │   └── (same 5-file pattern)
│   │   ├── auth-token/
│   │   │   ├── auth-token.entity.js
│   │   │   ├── auth-token.service.js
│   │   │   └── auth-token.helper.js
│   │   ├── auth-template/
│   │   │   ├── auth-template.entity.js
│   │   │   ├── auth-template.service.js
│   │   │   └── auth-template.helper.js
│   │   ├── verification-token/
│   │   │   ├── verification-token.entity.js
│   │   │   ├── verification-token.service.js
│   │   │   └── verification-token.helper.js
│   │   ├── notification/
│   │   │   └── notification.service.js
│   │   ├── common/
│   │   │   ├── common.helper.js
│   │   │   └── common.service.js
│   │   └── doc/
│   │       └── doc.router.js
│   └── utils/
│       ├── database/
│       │   └── index.js        # Sequelize instance + sync
│       ├── error/
│       │   └── index.js        # CustomError class
│       └── seed/
│           ├── index.js
│           ├── user.seed.js
│           ├── role.seed.js
│           └── auth-template.seed.js
├── test/
│   ├── setup.js
│   └── <module>/<module>.test.js
├── .env
├── .env.sample
├── .env.test
├── .babelrc
├── .mocharc.json
├── jsconfig.json
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
npm init -y

# Core
npm add express cors dotenv bcryptjs jsonwebtoken validator handlebars lodash \
        sequelize pg pg-hstore sequelize-cli \
        @aws-sdk/client-ses axios

# Dev
npm add -D @babel/core @babel/register @babel/node @babel/preset-env \
           babel-node nodemon eslint prettier

# Testing
npm add -D mocha chai
```

---

## package.json scripts

```json
{
  "scripts": {
    "build": "rm -rf ./build && npm run lint && babel src -d build --copy-files",
    "compose:dev-down": "docker compose -f docker-compose.dev.yml down -v",
    "compose:dev-up":   "docker compose -f docker-compose.dev.yml up -d --build",
    "compose:prod-down":"docker compose -f docker-compose.prod.yml down -v",
    "compose:prod-up":  "docker compose -f docker-compose.prod.yml up -d --build",
    "compose:test-down":"docker compose -f docker-compose.test.yml down -v --remove-orphans",
    "compose:test-up":  "docker compose -f docker-compose.test.yml up --build --abort-on-container-exit --exit-code-from test_runner test_runner",
    "dev":      "npm run lint && nodemon -e js -w . --exec babel-node src/server.js",
    "format":   "prettier . --write",
    "lint":     "eslint --quiet . --ignore-pattern build/ --ignore-pattern test/",
    "lint-fix": "eslint --quiet . --fix",
    "mocha":    "mocha --require @babel/register --file test/setup.js --recursive test/**/*.test.js --timeout 60000",
    "test":     "npm run compose:test-down && npm run compose:test-up"
  }
}
```

---

## .babelrc

```json
{
  "presets": [
    ["@babel/preset-env", { "targets": { "node": "current" } }]
  ]
}
```

---

## jsconfig.json

```json
{
  "compilerOptions": {
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "target": "ESNext",
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "build"]
}
```

---

## .mocharc.json

```json
{
  "exit": true,
  "require": "@babel/register",
  "spec": "test/**/*.test.js",
  "timeout": 10000
}
```

---

## src/server.js

```javascript
import 'dotenv/config'
import cors from 'cors'
import express from 'express'
import { sequelize } from './utils/database/index.js'
import routes from './routes/index.js'
import { error } from './middlewares/index.js'

const app = express()

app.use(cors({ origin: '*' }))
app.use(express.json())

app.use('/', routes)
app.use(error)

const PORT = process.env.PORT || 3000

const startServer = async () => {
  await sequelize.authenticate()
  console.log('Database connected')
  app.listen(PORT, () => {
    console.log(`====> Server running on port http://localhost:${PORT} <====`)
  })
}

startServer()
```

---

## src/routes/index.js

```javascript
import express from 'express'
import { userRouter, permissionRouter, roleRouter, roleUserRouter, rolePermissionRouter } from '../modules/routers.js'
import docRouter from '../modules/doc/doc.router.js'

const router = express.Router()

router.get('/', (req, res) => res.json({ message: 'Welcome to the API service!', success: true }))

router.use('/docs', docRouter)
router.use('/users', userRouter)
router.use('/permissions', permissionRouter)
router.use('/roles', roleRouter)
router.use('/role-users', roleUserRouter)
router.use('/role-permissions', rolePermissionRouter)

export default router
```

---

## Module file pattern (5 files per module)

Every module under `src/modules/<name>/` follows this exact structure:

### `<name>.entity.js` — Sequelize model
```javascript
import { DataTypes } from 'sequelize'
import { sequelize } from '../../utils/database/index.js'

const User = sequelize.define('User', {
  id:         { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
  email:      { type: DataTypes.STRING, allowNull: false, unique: true },
  password:   { type: DataTypes.STRING, allowNull: true },
  first_name: { type: DataTypes.STRING, allowNull: true },
  last_name:  { type: DataTypes.STRING, allowNull: true },
  status:     { type: DataTypes.ENUM('active','inactive','unverified','invited'), defaultValue: 'unverified' },
}, { tableName: 'users', underscored: true, timestamps: true })

export default User
```

### `<name>.helper.js` — Query builders + data transforms
```javascript
import User from './user.entity.js'

export const countUsers = (options = {}) => User.count(options)

export const getUser = (options = {}) => User.findOne(options)

export const getUsers = (options = {}) => User.findAll(options)

export const getUsersForQuery = async ({ page = 1, pageSize = 20, where = {}, order = [] } = {}) => {
  const offset = (page - 1) * pageSize
  const { count, rows } = await User.findAndCountAll({ where, order, limit: pageSize, offset })
  return {
    data: rows,
    meta_data: { page, pageSize, total: count, hasNext: offset + rows.length < count },
  }
}
```

### `<name>.service.js` — Business logic
```javascript
import { CustomError } from '../../utils/error/index.js'
import { getUser, getUsers, getUsersForQuery } from './user.helper.js'

export const getUserById = async (id) => {
  const user = await getUser({ where: { id } })
  if (!user) throw new CustomError(404, 'User not found')
  return user
}
```

### `<name>.controller.js` — Request/response handlers
```javascript
export const getUserController = async (req, res, next) => {
  try {
    const user = await getUserById(req.params.id)
    res.json({ data: user, success: true })
  } catch (err) {
    next(err)
  }
}
```

### `<name>.router.js` — Express route definitions
```javascript
import express from 'express'
import { authorizer } from '../../middlewares/index.js'
import { getUserController } from './user.controller.js'

const router = express.Router()

router.get('/:id', authorizer(), getUserController)

export default router
```

---

## src/middlewares/authorizer.js

```javascript
import { verifyJWTToken } from '../modules/common/common.service.js'
import { getAuthUserWithRolesAndPermissions } from '../modules/user/user.helper.js'
import { CustomError } from '../utils/error/index.js'

export const authorizer = (requiredRoles = []) => async (req, res, next) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '')
    if (!token) throw new CustomError(401, 'Unauthorized')

    const { user_id } = verifyJWTToken(token)
    const user = await getAuthUserWithRolesAndPermissions(user_id)
    if (!user) throw new CustomError(401, 'Unauthorized')

    if (requiredRoles.length) {
      const userRoles = user.Roles?.map(r => r.name) ?? []
      const hasRole = requiredRoles.some(r => userRoles.includes(r))
      if (!hasRole) throw new CustomError(403, 'Forbidden')
    }

    req.user = user
    next()
  } catch (err) {
    next(err)
  }
}
```

---

## src/utils/error/index.js

```javascript
export class CustomError extends Error {
  constructor(statusCode, message) {
    super(message)
    this.statusCode = statusCode
  }
}
```

---

## src/middlewares/error.js

```javascript
export const error = (err, req, res, next) => {
  const statusCode = err.statusCode ?? 500
  const code = err.message?.toUpperCase().replace(/\s+/g, '_')
  res.status(statusCode).json({ error: code, success: false })
}
```

---

## src/utils/database/index.js

```javascript
import { Sequelize } from 'sequelize'

export const sequelize = new Sequelize(process.env.DATABASE_URL, {
  dialect: 'postgres',
  logging: process.env.NODE_ENV === 'development' ? console.log : false,
  pool: { max: 5, min: 0, acquire: 30000, idle: 10000 },
})
```

---

## Barrel files

### src/modules/routers.js
```javascript
export { default as userRouter }           from './user/user.router.js'
export { default as permissionRouter }     from './permission/permission.router.js'
export { default as roleRouter }           from './role/role.router.js'
export { default as roleUserRouter }       from './role-user/role-user.router.js'
export { default as rolePermissionRouter } from './role-permission/role-permission.router.js'
```

### src/modules/services.js
```javascript
export * from './user/user.service.js'
export * from './permission/permission.service.js'
export * from './role/role.service.js'
export * from './role-user/role-user.service.js'
export * from './role-permission/role-permission.service.js'
export * from './auth-token/auth-token.service.js'
export * from './auth-template/auth-template.service.js'
export * from './verification-token/verification-token.service.js'
export * from './notification/notification.service.js'
export * from './common/common.service.js'
```

### src/modules/entities.js
```javascript
export { default as User }              from './user/user.entity.js'
export { default as Permission }        from './permission/permission.entity.js'
export { default as Role }              from './role/role.entity.js'
export { default as RoleUser }          from './role-user/role-user.entity.js'
export { default as RolePermission }    from './role-permission/role-permission.entity.js'
export { default as AuthToken }         from './auth-token/auth-token.entity.js'
export { default as AuthTemplate }      from './auth-template/auth-template.entity.js'
export { default as VerificationToken } from './verification-token/verification-token.entity.js'
```

---

## src/modules/common/common.service.js

```javascript
import bcrypt from 'bcryptjs'
import jwt from 'jsonwebtoken'
import { isEmail, isStrongPassword } from 'validator'

export const generateHashPassword = (password) =>
  bcrypt.hash(password, parseInt(process.env.BCRYPT_ROUNDS || '10', 10))

export const compareHashPassword = (password, hash) => bcrypt.compare(password, hash)

export const generateJWTToken = (payload, options = {}) =>
  jwt.sign(payload, process.env.JWT_SECRET, {
    issuer: process.env.JWT_ISSUER,
    ...options,
  })

export const verifyJWTToken = (token) =>
  jwt.verify(token, process.env.JWT_SECRET, { issuer: process.env.JWT_ISSUER })

export const decodeJWTToken = (token) => jwt.decode(token)

export const validateEmail    = (email)    => isEmail(email)
export const validatePassword  = (password) =>
  isStrongPassword(password, { minLength: 8, minLowercase: 1, minUppercase: 1, minNumbers: 1, minSymbols: 1 })
```

---

## src/modules/notification/notification.service.js

```javascript
import { SESClient, SendEmailCommand } from '@aws-sdk/client-ses'
import Handlebars from 'handlebars'
import { getAuthTemplate } from '../auth-template/auth-template.helper.js'

const ses = new SESClient({ region: process.env.AWS_REGION || 'us-east-1' })

export const sendNotification = async ({ event, to, data }) => {
  const template = await getAuthTemplate({ where: { event } })
  if (!template) throw new Error(`Template not found for event: ${event}`)

  const body    = Handlebars.compile(template.body)(data)
  const subject = Handlebars.compile(template.subject)(data)

  if (process.env.NODE_ENV === 'test') {
    console.log(`[NOTIFICATION] To: ${to} | Subject: ${subject}`)
    return
  }

  await ses.send(new SendEmailCommand({
    Source: process.env.FROM_EMAIL,
    Destination: { ToAddresses: [to] },
    Message: {
      Subject: { Data: subject },
      Body:    { Html: { Data: body } },
    },
  }))
}
```

---

## Verification token pattern

Tokens are 6-digit numeric OTPs with a 5-minute expiry, stored in `VerificationToken` table.

```javascript
// verification-token.service.js
import crypto from 'crypto'

export const createVerificationToken = async ({ user_id, email, type }) => {
  const token      = crypto.randomInt(100000, 999999).toString()
  const expired_at = new Date(Date.now() + 5 * 60 * 1000)   // 5 minutes
  await VerificationToken.create({ user_id, email, token, type, expired_at })
  return token
}

export const validateVerificationToken = async ({ user_id, token, type }) => {
  const record = await VerificationToken.findOne({
    where: { user_id, token, type, status: 'unverified' },
  })
  if (!record)                              throw new CustomError(400, 'Invalid token')
  if (new Date() > record.expired_at)       throw new CustomError(400, 'Token expired')
  await record.update({ status: 'verified' })
  return record
}
```

---

## GraphQL variant (Express_GraphQL)

When `GRAPHQL = yes`, add `src/graphql/` alongside `src/routes/`:

```
src/graphql/
├── schema.js           # merges typeDefs + resolvers
├── server.js           # ApolloServer instance
├── directives/
│   └── auth.js         # @auth directive
├── typeDefs/
│   ├── auth.graphql
│   ├── common.graphql
│   ├── user.graphql
│   ├── role.graphql
│   ├── permission.graphql
│   ├── role-user.graphql
│   └── role-permission.graphql
└── resolvers/
    ├── index.js
    ├── auth/
    ├── user/
    ├── role/
    ├── permission/
    ├── role-user/
    └── role-permission/
```

Install: `npm add @apollo/server @as-integrations/express5 graphql @graphql-tools/merge`

Wire in `src/server.js`:
```javascript
import { apolloServer }    from './graphql/server.js'
import { expressMiddleware } from '@as-integrations/express5'

await apolloServer.start()
app.use('/graphql', express.json(), expressMiddleware(apolloServer, {
  context: async ({ req }) => ({ user: req.user }),
}))
```

---

## Docker (three environments)

| File | Purpose |
|---|---|
| `Dockerfile.Dev` + `docker-compose.dev.yml` | Hot-reload dev with nodemon |
| `Dockerfile.Prod` + `docker-compose.prod.yml` | Production build (Babel-compiled) |
| `Dockerfile.Test` + `docker-compose.test.yml` | Test runner + isolated test DB |

### Dockerfile.Dev
```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
CMD ["npm", "run", "dev"]
EXPOSE 3000
```

### docker-compose.dev.yml (Postgres)
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
    ports: ['3000:3000']
    env_file: .env
    depends_on: { postgres: { condition: service_healthy } }
    volumes: [.:/app, /app/node_modules]
volumes:
  postgres_data:
```

---

## Test setup endpoint

The test suite requires a `POST /test/setup` endpoint (only active when `NODE_ENV=test`) that:
1. Syncs the DB schema (`sequelize.sync({ force: true })`)
2. Seeds roles and auth templates
3. Returns `{ success: true }`

And `GET /test/verification-tokens?email=...&type=...` to fetch OTP tokens in tests.

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
PORT=3000
REFRESH_TOKEN_EXPIRY=7d
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=postgres
PGADMIN_DEFAULT_EMAIL=postgres@postgres.com
PGADMIN_DEFAULT_PASSWORD=postgres
AWS_REGION=us-east-1
```
