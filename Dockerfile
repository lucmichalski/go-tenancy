FROM golang:alpine3.11 AS builder
MAINTAINER x0rzkov

RUN apk add --no-cache make gcc g++ ca-certificates musl-dev git

COPY . /go/src/github.com/snowlyg/go-tenancy
WORKDIR /go/src/github.com/snowlyg/go-tenancy

RUN go build 

FROM alpine:3.11 AS runtime
MAINTAINER x0rzkov

ARG TINI_VERSION=${TINI_VERSION:-"v0.18.0"}

# Install tini to /usr/local/sbin
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-muslc-amd64 /usr/local/sbin/tini

# Install runtime dependencies & create runtime user
RUN apk --no-cache --no-progress add ca-certificates \
 && chmod +x /usr/local/sbin/tini && mkdir -p /opt \
 && adduser -D snowlyg -h /opt/go-tenancy -s /bin/sh \
 && su snowlyg -c 'cd /opt/go-tenancy; mkdir -p bin config data ui'

# Switch to user context
# USER snowlyg
WORKDIR /opt/snowlyg/data

# copy executable
COPY --from=builder /go/src/github.com/snowlyg/go-tenancy/go-tenancy /opt/go-tenancy/bin/go-tenancy

ENV PATH $PATH:/opt/go-tenancy/bin

# Container configuration
EXPOSE 8080
# VOLUME ["/opt/ncarlier/data"]
ENTRYPOINT ["tini", "-g", "--"]
CMD ["/opt/go-tenancy/bin/go-tenancy"]
