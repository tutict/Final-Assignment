package handler

import (
	"bytes"
	"io"
	"regexp"
	"strings"

	"github.com/gin-gonic/gin"
)

var (
	localDateTimeJSON = regexp.MustCompile(`"((?:19|20)\d{2}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})"`)
	localDateJSON     = regexp.MustCompile(`"((?:19|20)\d{2}-\d{2}-\d{2})"`)
)

// flexibleLocalTimeBody accepts the frontend LocalDateTime/LocalDate strings
// (no timezone) that Spring parses natively and Go's time.Time does not.
func FlexibleLocalTimeBody() gin.HandlerFunc {
	return func(c *gin.Context) {
		if c.Request == nil || c.Request.Body == nil || !strings.Contains(c.GetHeader("Content-Type"), "json") {
			c.Next()
			return
		}
		body, err := io.ReadAll(c.Request.Body)
		_ = c.Request.Body.Close()
		if err != nil {
			c.Request.Body = io.NopCloser(bytes.NewReader(nil))
			c.Next()
			return
		}
		normalized := normalizeLocalTimes(body)
		c.Request.Body = io.NopCloser(bytes.NewReader(normalized))
		c.Request.ContentLength = int64(len(normalized))
		c.Next()
	}
}

func normalizeLocalTimes(body []byte) []byte {
	body = localDateTimeJSON.ReplaceAll(body, []byte(`"${1}+08:00"`))
	body = localDateJSON.ReplaceAll(body, []byte(`"${1}T00:00:00+08:00"`))
	return body
}
