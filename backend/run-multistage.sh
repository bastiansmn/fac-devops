docker stop $(docker ps --filter name=tp1-basic -q)

docker build . -t tp1/basic-multistage -f Dockerfile.multistage

docker run \
   --name tp1-basic-java \
   --rm \
   -p 8080:8080 \
   tp1/basic-multistage