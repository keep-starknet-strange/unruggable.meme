# Notice that the base image is build from scratch (not an OS like Ubuntu),
# so the binary is in a location that depends on the build.
# For this reason we stick to a specific version and architecture.
#
# When updating the image you also need to update the entrypoint below.
#
# - docker image pull quay.io/apibara/sink-postgres:0.7.0-x86_64
# - docker image inspect quay.io/apibara/sink-postgres:0.7.0-x86_64 | jq '.[].Config.Entrypoint'
FROM quay.io/apibara/sink-postgres:0.7.0-x86_64

WORKDIR /app
COPY ./src/* /app

ENTRYPOINT ["/nix/store/rh1g8pb7wfnyr527jfmkkc5lm3sa1f0l-apibara-sink-postgres-0.7.0/bin/apibara-sink-postgres"]
