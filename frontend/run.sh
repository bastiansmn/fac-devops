docker network create frontend-network

docker network connect frontend-network tp1-back

docker build -t tp1/front .

docker stop $(docker ps --filter name=tp1-front -q)

docker run \
   --name tp1-front \
   --network frontend-network \
   --rm \
   -p 81:80 \
   tp1/front
