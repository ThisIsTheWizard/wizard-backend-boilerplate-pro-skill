package handler

import (
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
)

var startTime = time.Now()

// HealthCheck godoc
// @Summary Health check
// @Tags health
// @Success 200 {object} map[string]interface{}
// @Router /health [get]
func HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "ok",
		"version": "1.0.0",
		"uptime":  int(time.Since(startTime).Seconds()),
		"env":     getEnvOrDefault("ENV", "development"),
		"db":      "connected",
	})
}

func getEnvOrDefault(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
