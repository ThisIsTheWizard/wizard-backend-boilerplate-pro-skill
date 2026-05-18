# Echo — Reference

**Language:** Go 1.21+
**Version:** echo v4.x (use `github.com/labstack/echo/v4@latest`)
**Docs:** https://echo.labstack.com

## Directory structure (after scaffold)

```
<APP_NAME>/
├── cmd/
│   └── server/
│       └── main.go
├── internal/
│   ├── handler/
│   │   ├── health.go
│   │   ├── auth.go
│   │   └── users.go
│   ├── service/
│   ├── repository/
│   ├── middleware/
│   │   ├── auth.go         # auth provider bootstrap
│   │   └── logger.go
│   ├── model/
│   └── router/
│       └── router.go
├── pkg/db/
├── docs/                   # swag-generated spec
├── .env
├── go.mod
└── Dockerfile
```

## Init commands

```bash
mkdir "$APP_NAME" && cd "$APP_NAME"
go mod init "$APP_NAME"

go get github.com/labstack/echo/v4
go get github.com/labstack/echo/v4/middleware
go get github.com/joho/godotenv
go get github.com/swaggo/swag/cmd/swag
go get github.com/swaggo/echo-swagger
go get github.com/swaggo/files
```

## cmd/server/main.go

```go
package main

import (
    "log"
    "os"

    "github.com/joho/godotenv"
    _ "APP_NAME/docs"
    "APP_NAME/internal/router"
)

func main() {
    if err := godotenv.Load(); err != nil {
        log.Println("No .env file found")
    }

    e := router.Setup()

    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Printf("Server starting on http://localhost:%s", port)
    log.Printf("Swagger UI: http://localhost:%s/docs/index.html", port)
    e.Logger.Fatal(e.Start(":" + port))
}
```

## internal/router/router.go

```go
package router

import (
    "net/http"
    "time"

    "github.com/labstack/echo/v4"
    "github.com/labstack/echo/v4/middleware"
    echoSwagger "github.com/swaggo/echo-swagger"

    "APP_NAME/internal/handler"
    mw "APP_NAME/internal/middleware"
)

func Setup() *echo.Echo {
    e := echo.New()
    e.HideBanner = true

    // Built-in middleware
    e.Use(middleware.Logger())
    e.Use(middleware.Recover())
    e.Use(middleware.CORSWithConfig(middleware.CORSConfig{
        AllowOrigins: []string{"*"},
        AllowMethods: []string{http.MethodGet, http.MethodPost, http.MethodPut, http.MethodDelete},
        AllowHeaders: []string{echo.HeaderOrigin, echo.HeaderContentType, echo.HeaderAuthorization},
    }))
    e.Use(middleware.RateLimiter(middleware.NewRateLimiterMemoryStore(100)))

    // Swagger
    e.GET("/docs/*", echoSwagger.WrapHandler)

    // Health
    e.GET("/health", handler.HealthCheck)

    // Auth
    auth := e.Group("/auth")
    auth.POST("/register", handler.Register)
    auth.POST("/login", handler.Login)
    auth.POST("/refresh", handler.RefreshToken)
    auth.GET("/me", handler.Me, mw.RequireAuth())

    // Users (protected)
    users := e.Group("/users", mw.RequireAuth())
    users.GET("", handler.ListUsers)
    users.POST("", handler.CreateUser)
    users.GET("/:id", handler.GetUser)
    users.PUT("/:id", handler.UpdateUser)
    users.DELETE("/:id", handler.DeleteUser)

    return e
}
```

## Handler pattern

```go
package handler

import (
    "net/http"
    "github.com/labstack/echo/v4"
)

type CreateUserRequest struct {
    Email    string `json:"email" validate:"required,email"`
    Password string `json:"password" validate:"required,min=8"`
}

// @Summary Create user
// @Tags users
// @Accept json
// @Produce json
// @Param body body CreateUserRequest true "User data"
// @Success 201 {object} map[string]interface{}
// @Router /users [post]
func CreateUser(c echo.Context) error {
    req := new(CreateUserRequest)
    if err := c.Bind(req); err != nil {
        return echo.NewHTTPError(http.StatusBadRequest, err.Error())
    }
    if err := c.Validate(req); err != nil {
        return echo.NewHTTPError(http.StatusUnprocessableEntity, err.Error())
    }
    return c.JSON(http.StatusCreated, echo.Map{"id": "new-id"})
}
```

## Custom validator (go-playground)

```bash
go get github.com/go-playground/validator/v10
```

```go
// main.go / router.go
import validator "github.com/go-playground/validator/v10"

type CustomValidator struct { v *validator.Validate }
func (cv *CustomValidator) Validate(i interface{}) error {
    return cv.v.Struct(i)
}
e.Validator = &CustomValidator{v: validator.New()}
```

## Error handler

```go
e.HTTPErrorHandler = func(err error, c echo.Context) {
    code := http.StatusInternalServerError
    msg := "Internal server error"
    if he, ok := err.(*echo.HTTPError); ok {
        code = he.Code
        msg = fmt.Sprintf("%v", he.Message)
    }
    c.JSON(code, echo.Map{"error": msg})
}
```

## Generate Swagger docs

```bash
swag init -g cmd/server/main.go
```

## Key differences from Gin

| Feature | Gin | Echo |
|---|---|---|
| Router | `gin.Engine` | `echo.Echo` |
| Context | `*gin.Context` | `echo.Context` |
| JSON response | `c.JSON(200, gin.H{...})` | `c.JSON(200, echo.Map{...})` |
| Path param | `c.Param("id")` | `c.Param("id")` |
| Query param | `c.DefaultQuery("k","v")` | `c.QueryParam("k")` |
| Middleware | `r.Use(fn)` | `e.Use(fn)` |
| Grouped routes | `r.Group("/path")` | `e.Group("/path")` |
| Built-in rate limit | via ulule/limiter | `middleware.RateLimiter` |
