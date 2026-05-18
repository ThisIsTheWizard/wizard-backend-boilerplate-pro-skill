# Gin — Reference

**Language:** Go 1.21+
**Version:** gin v1.x (use `github.com/gin-gonic/gin@latest`)
**Docs:** https://gin-gonic.com/docs

## Directory structure (after scaffold)

```
<APP_NAME>/
├── cmd/
│   └── server/
│       └── main.go         # Entry point
├── internal/
│   ├── handler/            # HTTP handlers (thin layer, calls service)
│   │   ├── health.go
│   │   ├── auth.go
│   │   └── users.go
│   ├── service/            # Business logic
│   │   ├── auth_service.go
│   │   └── user_service.go
│   ├── repository/         # Data access layer
│   │   └── user_repo.go
│   ├── middleware/         # Gin middleware
│   │   ├── auth.go         # auth provider bootstrap
│   │   ├── cors.go
│   │   └── logger.go
│   ├── model/              # GORM models
│   │   └── user.go
│   └── router/
│       └── router.go       # Route registration
├── pkg/
│   └── db/
│       └── client.go       # GORM / mongo-driver setup
├── docs/                   # swag-generated OpenAPI spec
├── .env
├── .env.example
├── go.mod
├── go.sum
└── Dockerfile
```

## Init commands

```bash
mkdir "$APP_NAME" && cd "$APP_NAME"
go mod init "$APP_NAME"

go get github.com/gin-gonic/gin
go get github.com/gin-contrib/cors
go get github.com/joho/godotenv
go get github.com/ulule/limiter/v3
go get github.com/ulule/limiter/v3/drivers/middleware/gin
go get github.com/swaggo/swag/cmd/swag
go get github.com/swaggo/gin-swagger
go get github.com/swaggo/files
```

## cmd/server/main.go

```go
package main

import (
    "log"
    "os"

    "github.com/gin-gonic/gin"
    "github.com/joho/godotenv"
    _ "APP_NAME/docs" // swag-generated
    "APP_NAME/internal/router"
)

func main() {
    if err := godotenv.Load(); err != nil {
        log.Println("No .env file found")
    }

    r := gin.Default()
    router.Setup(r)

    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Printf("Server starting on http://localhost:%s", port)
    log.Printf("Swagger UI: http://localhost:%s/docs/index.html", port)
    r.Run(":" + port)
}
```

## internal/router/router.go

```go
package router

import (
    "time"

    "github.com/gin-contrib/cors"
    "github.com/gin-gonic/gin"
    swaggerfiles "github.com/swaggo/files"
    ginSwagger "github.com/swaggo/gin-swagger"
    "github.com/ulule/limiter/v3"
    "github.com/ulule/limiter/v3/drivers/middleware/gin"
    "github.com/ulule/limiter/v3/drivers/store/memory"

    "APP_NAME/internal/handler"
    "APP_NAME/internal/middleware"
)

func Setup(r *gin.Engine) {
    // CORS
    r.Use(cors.New(cors.Config{
        AllowOrigins: []string{"*"},
        AllowMethods: []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
        AllowHeaders: []string{"Origin", "Content-Type", "Authorization"},
    }))

    // Rate limit: 100 req/min
    rate, _ := limiter.NewRateFromFormatted("100-M")
    store := memory.NewStore()
    lm := limiter.New(store, rate)
    r.Use(mgin.NewMiddleware(lm))

    // Health
    r.GET("/health", handler.HealthCheck)

    // Swagger
    r.GET("/docs/*any", ginSwagger.WrapHandler(swaggerfiles.Handler))

    // Auth routes
    auth := r.Group("/auth")
    {
        auth.POST("/register", handler.Register)
        auth.POST("/login", handler.Login)
        auth.POST("/refresh", handler.RefreshToken)
        auth.GET("/me", middleware.RequireAuth(), handler.Me)
    }

    // Protected user routes
    users := r.Group("/users", middleware.RequireAuth())
    {
        users.GET("", handler.ListUsers)
        users.POST("", handler.CreateUser)
        users.GET("/:id", handler.GetUser)
        users.PUT("/:id", handler.UpdateUser)
        users.DELETE("/:id", handler.DeleteUser)
    }
}
```

## Handler pattern

```go
package handler

import (
    "net/http"
    "github.com/gin-gonic/gin"
)

// @Summary List users
// @Tags users
// @Security BearerAuth
// @Success 200 {array} model.User
// @Router /users [get]
func ListUsers(c *gin.Context) {
    page := c.DefaultQuery("page", "1")
    c.JSON(http.StatusOK, gin.H{"users": []interface{}{}, "page": page})
}
```

## Generate Swagger docs

```bash
# Install swag CLI
go install github.com/swaggo/swag/cmd/swag@latest

# Generate from annotations
swag init -g cmd/server/main.go
```

## Environment loading

```go
import "github.com/joho/godotenv"

godotenv.Load() // loads .env silently
os.Getenv("DATABASE_URL")
```

## Build and run

```bash
go run ./cmd/server
go build -o bin/server ./cmd/server
./bin/server
```
