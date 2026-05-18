# Mongoose — Reference

**Ecosystems:** Node.js / TypeScript (Express, Fastify, NestJS, Hono)
**Database:** MongoDB
**Docs:** https://mongoosejs.com/docs

## Install

```bash
$PM add mongoose
$PM add -D @types/mongoose  # Only for older setups; Mongoose ships its own types
```

## Connection setup (src/lib/db.ts)

```typescript
import mongoose from 'mongoose';

let isConnected = false;

export async function connectDB() {
  if (isConnected) return;

  const conn = await mongoose.connect(process.env.MONGODB_URI!, {
    dbName: process.env.DB_NAME,
  });

  isConnected = conn.connections[0].readyState === 1;
  console.log(`MongoDB connected: ${conn.connection.host}`);
}

// Graceful disconnect on shutdown
process.on('SIGINT', async () => {
  await mongoose.connection.close();
  process.exit(0);
});
```

## User schema + model (src/models/User.ts)

```typescript
import { Schema, model, Document, Types } from 'mongoose';

export interface IUser extends Document {
  _id: Types.ObjectId;
  email: string;
  password: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const userSchema = new Schema<IUser>(
  {
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    password: { type: String, required: true, select: false }, // exclude from queries by default
    isActive: { type: Boolean, default: true },
  },
  {
    timestamps: true,           // auto createdAt + updatedAt
    versionKey: false,
    toJSON: {
      transform(_doc, ret) {
        ret.id = ret._id.toHexString();
        delete ret._id;
        delete ret.password;
        return ret;
      },
    },
  }
);

userSchema.index({ email: 1 });

export const User = model<IUser>('User', userSchema);
```

## Common query patterns

```typescript
import { User } from '../models/User';

// Find with pagination + search
const page = 1, limit = 20;
const filter = search ? { email: { $regex: search, $options: 'i' } } : {};

const [users, total] = await Promise.all([
  User.find(filter)
      .select('-password')
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .lean(),
  User.countDocuments(filter),
]);

// Create
const user = await User.create({ email, password: hashed });

// Find one
const user = await User.findById(id).select('+password'); // re-include excluded field

// Update
const updated = await User.findByIdAndUpdate(id, { $set: { isActive } }, { new: true });

// Delete
await User.findByIdAndDelete(id);

// Exists check
const exists = await User.exists({ email });
```

## NestJS + Mongoose

```bash
$PM add @nestjs/mongoose mongoose
```

```typescript
// app.module.ts
import { MongooseModule } from '@nestjs/mongoose';

@Module({
  imports: [
    MongooseModule.forRoot(process.env.MONGODB_URI!),
  ],
})
export class AppModule {}

// users.module.ts
@Module({
  imports: [MongooseModule.forFeature([{ name: User.name, schema: UserSchema }])],
  providers: [UsersService],
})
export class UsersModule {}

// users.service.ts
@Injectable()
export class UsersService {
  constructor(@InjectModel(User.name) private userModel: Model<User>) {}

  async findAll() {
    return this.userModel.find().select('-password').lean();
  }
}
```

## MongoDB connection string format

```env
MONGODB_URI=mongodb://user:password@localhost:27017/dbname?authSource=admin
# MongoDB Atlas
MONGODB_URI=mongodb+srv://user:password@cluster.mongodb.net/dbname
```

## Mongoose vs Prisma (MongoDB)

| Feature | Mongoose | Prisma (MongoDB) |
|---|---|---|
| Schema flexibility | Flexible (subdocuments, mixed types) | Strict schema |
| Validation | Schema-level rules | Zod/manual |
| Population | `populate()` | `include` |
| Aggregation | `aggregate()` pipeline | Limited support |
| TypeScript | Good (manual typing) | Excellent (auto-generated) |
| Status | Stable, battle-tested | MongoDB support is GA |

Use Mongoose when you need aggregation pipelines, flexible schemas, or
subdocuments. Use Prisma when you prefer auto-generated types and want a
unified ORM across SQL + MongoDB.
