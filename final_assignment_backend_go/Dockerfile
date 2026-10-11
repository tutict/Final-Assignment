# Multi-stage build for the Go backend (module root: final_assignment_backend_go).
# Build:  docker build -f final_assignment_backend_go/Dockerfile -t final-assignment-go:latest .
# Run:    see compose.app.yml — the app reads BACKEND_PORT / DB_* / REDIS_* env vars.

FROM golang:1.25 AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY project ./project
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/app ./project/cmd/app

FROM alpine:3.20
RUN apk add --no-cache ca-certificates tzdata && adduser -D -u 10001 appuser
WORKDIR /app
COPY --from=build /out/app ./app
USER appuser
EXPOSE 8080
ENTRYPOINT ["./app"]
