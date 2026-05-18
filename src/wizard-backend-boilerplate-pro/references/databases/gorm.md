# GORM — Reference

**Ecosystems:** Go (Gin, Echo)
**Databases:** PostgreSQL, MySQL, SQLite, SQL Server
**Docs:** https://gorm.io/docs

## Install

```bash
go get gorm.io/gorm

# PostgreSQL driver
go get gorm.io/driver/postgres

# MySQL driver
go get gorm.io/driver/mysql

# SQLite driver
go get gorm.io/driver/sqlite
```

## Model definition (internal/model/user.go)

```go
package model

import (
    "time"
    "github.com/google/uuid"
    "gorm.io/gorm"
)

type User struct {
    ID        string         `gorm:"type:uuid;primaryKey" json:"id"`
    Email     string         `gorm:"uniqueIndex;not null" json:"email"`
    Password  string         `gorm:"not null" json:"-"` // never serialize
    IsActive  bool           `gorm:"default:true" json:"is_active"`
    CreatedAt time.Time      `json:"created_at"`
    UpdatedAt time.Time      `json:"updated_at"`
    DeletedAt gorm.DeletedAt `gorm:"index" json:"-"` // soft delete
}

func (u *User) BeforeCreate(tx *gorm.DB) error {
    u.ID = uuid.New().String()
    return nil
}
```

## Database client (pkg/db/client.go)

```go
package db

import (
    "fmt"
    "log"
    "os"

    "gorm.io/driver/postgres"
    "gorm.io/driver/mysql"
    "gorm.io/driver/sqlite"
    "gorm.io/gorm"
    "gorm.io/gorm/logger"
    "APP_NAME/internal/model"
)

var DB *gorm.DB

func Connect() *gorm.DB {
    var dialector gorm.Dialector

    dbType := os.Getenv("DB_TYPE") // "postgres" | "mysql" | "sqlite"
    switch dbType {
    case "mysql":
        dialector = mysql.Open(os.Getenv("DATABASE_URL"))
    case "sqlite":
        dialector = sqlite.Open(os.Getenv("DB_PATH"))
    default:
        dialector = postgres.Open(os.Getenv("DATABASE_URL"))
    }

    config := &gorm.Config{
        Logger: logger.Default.LogMode(
            map[string]logger.LogLevel{
                "development": logger.Info,
                "production":  logger.Error,
            }[os.Getenv("ENV")],
        ),
    }

    db, err := gorm.Open(dialector, config)
    if err != nil {
        log.Fatalf("Failed to connect to database: %v", err)
    }

    // Connection pool
    sqlDB, _ := db.DB()
    sqlDB.SetMaxOpenConns(25)
    sqlDB.SetMaxIdleConns(10)

    // Auto-migrate
    if err := db.AutoMigrate(&model.User{}); err != nil {
        log.Fatalf("AutoMigrate failed: %v", err)
    }

    DB = db
    return db
}
```

## Common query patterns

```go
import (
    "gorm.io/gorm"
    "APP_NAME/internal/model"
)

// Find with pagination + search
func FindUsers(db *gorm.DB, page, limit int, search string) ([]model.User, int64, error) {
    var users []model.User
    var total int64

    q := db.Model(&model.User{})
    if search != "" {
        q = q.Where("email ILIKE ?", "%"+search+"%")
    }

    q.Count(&total)
    result := q.Order("created_at DESC").
        Offset((page - 1) * limit).
        Limit(limit).
        Find(&users)

    return users, total, result.Error
}

// Create
func CreateUser(db *gorm.DB, email, hashedPassword string) (*model.User, error) {
    user := &model.User{Email: email, Password: hashedPassword}
    result := db.Create(user)
    return user, result.Error
}

// Find by ID
func FindUserByID(db *gorm.DB, id string) (*model.User, error) {
    var user model.User
    result := db.First(&user, "id = ?", id)
    return &user, result.Error
}

// Update
func UpdateUser(db *gorm.DB, id string, updates map[string]interface{}) error {
    return db.Model(&model.User{}).Where("id = ?", id).Updates(updates).Error
}

// Soft delete
func DeleteUser(db *gorm.DB, id string) error {
    return db.Delete(&model.User{}, "id = ?", id).Error
}

// Transaction
func CreateUserWithAPIKey(db *gorm.DB, email, password, hashedKey string) error {
    return db.Transaction(func(tx *gorm.DB) error {
        user := &model.User{Email: email, Password: password}
        if err := tx.Create(user).Error; err != nil {
            return err
        }
        key := &model.APIKey{UserID: user.ID, HashedKey: hashedKey}
        return tx.Create(key).Error
    })
}
```

## Connection string formats

```env
# PostgreSQL
DATABASE_URL=host=localhost user=postgres password=secret dbname=app port=5432 sslmode=disable

# Or URL format (requires postgres driver URL parsing)
DATABASE_URL=postgres://postgres:secret@localhost:5432/app?sslmode=disable

# MySQL
DATABASE_URL=user:password@tcp(localhost:3306)/dbname?charset=utf8mb4&parseTime=True&loc=Local

# SQLite
DB_PATH=./dev.db
DB_TYPE=sqlite
```

## Migrations (golang-migrate)

For production, use `golang-migrate` instead of AutoMigrate:

```bash
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

migrate -path ./migrations -database "$DATABASE_URL" up
migrate -path ./migrations -database "$DATABASE_URL" down 1
```

Create migration file:
```bash
migrate create -ext sql -dir migrations -seq add_users_table
```
