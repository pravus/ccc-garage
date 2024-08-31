FROM alpine:3 as garage-builder

ENV GARAGE_VERSION=1.0.0
ENV GARAGE_SHA256=70fa89f732a3de4bb2d1158a2e89c521a993a734eb24b6bd65e79c207c2e8868

RUN apk --no-cache update \
 && apk --no-cache upgrade \
 && apk --no-cache add build-base cargo cargo-auditable curl libsodium-dev protoc sqlite-dev zstd-dev openssl-dev

WORKDIR /usr/src

RUN curl -sSLO "https://git.deuxfleurs.fr/Deuxfleurs/garage/archive/v${GARAGE_VERSION}.tar.gz" \
 && echo "${GARAGE_SHA256}  v${GARAGE_VERSION}.tar.gz" | sha256sum -cw - \
 && tar xzvf "v${GARAGE_VERSION}.tar.gz" \
 && cd garage \
 && export CARGO_PROFILE_RELEASE_OPT_LEVEL=2 \
 && export SODIUM_USE_PKG_CONFIG=1 \
 && cargo fetch --locked \
 && cargo auditable build --frozen --no-default-features --features k2v,lmdb,metrics,sqlite,system-libs,syslog --release \
 && cargo test --frozen --no-default-features --features k2v,lmdb,metrics,sqlite,system-libs,syslog --workspace


FROM alpine:3

RUN apk --no-cache update \
 && apk --no-cache upgrade \
 && apk --no-cache add ca-certificates libgcc libsodium sqlite-libs zstd-libs

COPY --from=garage-builder /usr/src/garage/target/release/garage /usr/bin

ENV ENV=/root/.ashrc

COPY entrypoint /
COPY root /root

ENTRYPOINT ["/entrypoint"]
