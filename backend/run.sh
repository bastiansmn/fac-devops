docker build . -t tp1/basic

docker stop $(docker ps --filter name=tp1 -q)

docker run \
   --name tp1-java \
   --rm \
   -it \
   tp1/basic