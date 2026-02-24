# Build the Go backend as a statically linked binary
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o texas-backend ./

# final image
FROM scratch
COPY --from=builder /app/texas-backend /texas-backend
EXPOSE 8080
ENTRYPOINT ["/texas-backend"]
