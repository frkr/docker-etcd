FROM alpine:latest
VOLUME /data
EXPOSE 2379
EXPOSE 2380

ARG ETCD_VERSION=3.2.17

RUN apk add --no-cache --update ca-certificates openssl tar drill bind-tools curl && \
    wget https://github.com/coreos/etcd/releases/download/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz && \
    tar xzvf etcd-v${ETCD_VERSION}-linux-amd64.tar.gz && \
    mv etcd-v${ETCD_VERSION}-linux-amd64/etcd* /bin/ && \
    apk del --purge tar openssl && \
    rm -Rf etcd-v${ETCD_VERSION}-linux-amd64* /var/cache/apk/*

COPY run.sh /bin/run.sh
RUN chmod +x /bin/run.sh
ENTRYPOINT ["/bin/run.sh"]
