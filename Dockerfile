FROM golang:alpine AS builder

RUN apk update && apk add git && mkdir /src && cd /src && git clone https://github.com/gohugoio/hugo.git
RUN cd /src/hugo && CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' .
RUN ls /src/hugo

FROM golang:alpine

COPY --from=builder /src/hugo /usr/local/bin
