package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"

	"my-api/internal/handler"
)

// @title my-api API
// @version 1.0
// @description Production-ready REST API
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file, using system environment")
	}

	if os.Getenv("ENV") == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.Default()

	r.GET("/health", handler.HealthCheck)
	// auth, users, blog route groups registered here by the skill

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("my-api running on http://localhost:%s", port)
	log.Printf("Swagger UI: http://localhost:%s/docs/index.html", port)

	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
