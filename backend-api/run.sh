docker network create backend-network

docker build -t tp1/back .

docker stop $(docker ps --filter name=tp1-back -q)

docker run \
   --name tp1-back \
   --network backend-network \
   --rm \
   -e SPRING_DATASOURCE_URL=jdbc:postgresql://tp1-db-postgres:5432/db \
   -e SPRING_DATASOURCE_USERNAME=usr \
   -e SPRING_DATASOURCE_PASSWORD=$POSTGRES_PASSWORD \
   tp1/back
