# Pulling postgres base image
FROM postgres:14.1-alpine

# Copying init scripts in the container
COPY ./scripts/*.sql /docker-entrypoint-initdb.d
