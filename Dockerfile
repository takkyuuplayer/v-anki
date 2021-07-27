FROM thevlang/vlang:buster-dev AS build
COPY . /workspace
WORKDIR /workspace
RUN v install
RUN v -prod main.v

FROM debian:buster-slim
RUN apt update \
 && apt install -y --no-install-recommends ca-certificates
RUN update-ca-certificates
WORKDIR /workspace
COPY ./static /workspace/static
COPY --from=build /workspace/main /workspace
CMD ["/workspace/main", "web"]
