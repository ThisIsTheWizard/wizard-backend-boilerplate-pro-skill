# Sequelize — Reference

**Ecosystems:** Node.js / JavaScript (Express, Fastify, Hono)
**Databases:** PostgreSQL, MySQL, SQLite
**Used by:** Express boilerplate (default ORM for SQL databases)

> The NestJS boilerplate uses **Prisma**, not Sequelize. This reference applies to Express only.

---

## Install

```bash
npm add sequelize pg pg-hstore      # PostgreSQL
# npm add sequelize mysql2           # MySQL
# npm add sequelize sqlite3          # SQLite
```

---

## Database connection (`src/utils/database/index.js`)

```javascript
import { Sequelize } from 'sequelize'

export const sequelize = new Sequelize(process.env.DATABASE_URL, {
  dialect: 'postgres',          // or 'mysql' | 'sqlite'
  logging: process.env.NODE_ENV === 'development' ? console.log : false,
  pool: { max: 5, min: 0, acquire: 30000, idle: 10000 },
})
```

For SQLite: `new Sequelize({ dialect: 'sqlite', storage: './dev.db' })`

---

## Model definition pattern (`<module>.entity.js`)

```javascript
import { DataTypes } from 'sequelize'
import { sequelize }  from '../../utils/database/index.js'

const User = sequelize.define('User', {
  id:           { type: DataTypes.UUID,   defaultValue: DataTypes.UUIDV4, primaryKey: true },
  email:        { type: DataTypes.STRING, allowNull: false, unique: true },
  password:     { type: DataTypes.STRING, allowNull: true },
  first_name:   { type: DataTypes.STRING, allowNull: true },
  last_name:    { type: DataTypes.STRING, allowNull: true },
  new_email:    { type: DataTypes.STRING, allowNull: true },
  phone_number: { type: DataTypes.STRING, allowNull: true },
  status:       {
    type: DataTypes.ENUM('active', 'inactive', 'unverified', 'invited'),
    defaultValue: 'unverified',
  },
  old_passwords: { type: DataTypes.ARRAY(DataTypes.STRING), defaultValue: [] },
}, { tableName: 'users', underscored: true, timestamps: true })

export default User
```

---

## Full schema — all entities

### Role

```javascript
const Role = sequelize.define('Role', {
  id:   { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
  name: { type: DataTypes.ENUM('admin', 'developer', 'moderator', 'user'), allowNull: false, unique: true },
}, { tableName: 'roles', underscored: true, timestamps: true })
```

### Permission

```javascript
const Permission = sequelize.define('Permission', {
  id:     { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
  action: { type: DataTypes.ENUM('create', 'read', 'update', 'delete'), allowNull: false },
  module: { type: DataTypes.ENUM('user', 'role', 'permission', 'role_user', 'role_permission'), allowNull: false },
}, { tableName: 'permissions', underscored: true, timestamps: true,
     indexes: [{ unique: true, fields: ['action', 'module'] }] })
```

### RoleUser (junction)

```javascript
const RoleUser = sequelize.define('RoleUser', {
  id:      { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
  user_id: { type: DataTypes.UUID, allowNull: false },
  role_id: { type: DataTypes.UUID, allowNull: false },
}, { tableName: 'role_users', underscored: true, timestamps: false,
     indexes: [{ unique: true, fields: ['user_id', 'role_id'] }] })
```

### RolePermission (junction with flag)

```javascript
const RolePermission = sequelize.define('RolePermission', {
  id:                { type: DataTypes.UUID,    defaultValue: DataTypes.UUIDV4, primaryKey: true },
  role_id:           { type: DataTypes.UUID,    allowNull: false },
  permission_id:     { type: DataTypes.UUID,    allowNull: false },
  can_do_the_action: { type: DataTypes.BOOLEAN, defaultValue: false },
  created_by:        { type: DataTypes.UUID,    allowNull: true },
}, { tableName: 'role_permissions', underscored: true, timestamps: true,
     indexes: [{ unique: true, fields: ['role_id', 'permission_id'] }] })
```

### AuthToken

```javascript
const AuthToken = sequelize.define('AuthToken', {
  id:            { type: DataTypes.UUID,   defaultValue: DataTypes.UUIDV4, primaryKey: true },
  user_id:       { type: DataTypes.UUID,   allowNull: false },
  access_token:  { type: DataTypes.TEXT,   allowNull: false, unique: true },
  refresh_token: { type: DataTypes.TEXT,   allowNull: false, unique: true },
}, { tableName: 'auth_tokens', underscored: true, timestamps: true })
```

### VerificationToken

```javascript
const VerificationToken = sequelize.define('VerificationToken', {
  id:         { type: DataTypes.UUID,   defaultValue: DataTypes.UUIDV4, primaryKey: true },
  user_id:    { type: DataTypes.UUID,   allowNull: false },
  email:      { type: DataTypes.STRING, allowNull: false },
  token:      { type: DataTypes.STRING, allowNull: false, unique: true },
  type:       { type: DataTypes.ENUM('user_verification', 'forgot_password'), allowNull: false },
  status:     { type: DataTypes.ENUM('unverified', 'verified', 'cancelled'), defaultValue: 'unverified' },
  expired_at: { type: DataTypes.DATE,   allowNull: false },
}, { tableName: 'verification_tokens', underscored: true, timestamps: true })
```

### AuthTemplate

```javascript
const AuthTemplate = sequelize.define('AuthTemplate', {
  id:      { type: DataTypes.UUID,   defaultValue: DataTypes.UUIDV4, primaryKey: true },
  event:   { type: DataTypes.STRING, allowNull: false, unique: true },
  subject: { type: DataTypes.STRING, allowNull: false },
  body:    { type: DataTypes.TEXT,   allowNull: false },
}, { tableName: 'auth_templates', underscored: true, timestamps: true })
```

---

## Associations (wire in `src/utils/database/index.js` after all models are imported)

```javascript
import User              from '../../modules/user/user.entity.js'
import Role              from '../../modules/role/role.entity.js'
import Permission        from '../../modules/permission/permission.entity.js'
import RoleUser          from '../../modules/role-user/role-user.entity.js'
import RolePermission    from '../../modules/role-permission/role-permission.entity.js'
import AuthToken         from '../../modules/auth-token/auth-token.entity.js'
import VerificationToken from '../../modules/verification-token/verification-token.entity.js'

// User ↔ Role (M2M through RoleUser)
User.belongsToMany(Role,       { through: RoleUser, foreignKey: 'user_id', otherKey: 'role_id', as: 'Roles' })
Role.belongsToMany(User,       { through: RoleUser, foreignKey: 'role_id', otherKey: 'user_id', as: 'Users' })

// Role ↔ Permission (M2M through RolePermission)
Role.belongsToMany(Permission, { through: RolePermission, foreignKey: 'role_id', otherKey: 'permission_id', as: 'Permissions' })
Permission.belongsToMany(Role, { through: RolePermission, foreignKey: 'permission_id', otherKey: 'role_id', as: 'Roles' })

// User 1→N AuthToken, VerificationToken
User.hasMany(AuthToken,         { foreignKey: 'user_id', as: 'AuthTokens' })
User.hasMany(VerificationToken, { foreignKey: 'user_id', as: 'VerificationTokens' })
AuthToken.belongsTo(User,         { foreignKey: 'user_id' })
VerificationToken.belongsTo(User, { foreignKey: 'user_id' })
```

---

## Sync / migrate

```javascript
// Development — sync with alter (preserves data)
await sequelize.sync({ alter: true })

// Test — sync with force (drops and recreates)
await sequelize.sync({ force: true })
```

There is no migration file system in the Express boilerplate — `sequelize.sync()` is used directly. For production with `sequelize-cli` migrations, see the CLI docs.

---

## Query patterns

```javascript
// Find one
const user = await User.findOne({ where: { email } })

// Find paginated
const { count, rows } = await User.findAndCountAll({
  where,
  limit:  pageSize,
  offset: (page - 1) * pageSize,
  order:  [['created_at', 'DESC']],
  include: [{ model: Role, as: 'Roles', through: { attributes: [] } }],
})

// Create
const user = await User.create({ email, password: hashed, status: 'unverified' })

// Update
await user.update({ status: 'active' })

// Upsert
const [record, created] = await Role.findOrCreate({ where: { name }, defaults: { name } })
```

---

## Helper pattern for queries

```javascript
// <module>.helper.js
export const prepareQuery = ({ search, status } = {}) => {
  const where = {}
  if (search) where[Op.or] = [{ email: { [Op.iLike]: `%${search}%` } }]
  if (status) where.status = status
  return where
}

export const getUsersForQuery = async ({ page = 1, pageSize = 20, search, status } = {}) => {
  const where  = prepareQuery({ search, status })
  const offset = (page - 1) * pageSize
  const { count, rows } = await User.findAndCountAll({
    where, limit: pageSize, offset,
    order:   [['created_at', 'DESC']],
    include: [{ model: Role, as: 'Roles', through: { attributes: [] } }],
  })
  return {
    data: rows,
    meta_data: { page, pageSize, total: count, hasNext: offset + rows.length < count },
  }
}
```

---

## MongoDB variant

When `DB = mongodb`, use **Mongoose** instead:

```bash
npm add mongoose
```

```javascript
// src/utils/database/index.js
import mongoose from 'mongoose'
export const connect = () => mongoose.connect(process.env.MONGODB_URL)

// user.entity.js  (Mongoose schema instead of Sequelize model)
import mongoose from 'mongoose'
const userSchema = new mongoose.Schema({ email: String, password: String, status: String }, { timestamps: true })
export default mongoose.model('User', userSchema)
```
