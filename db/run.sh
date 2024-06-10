docker network create app-network

docker stop $(docker ps --filter name=tp1 -q)

# Volume ./data pour persister les données
# Private network pour isoler la DB et communiquer avec adminer
docker run \
   --name tp1-db \
   --network app-network \
   --rm \
   -p 5433:5432 \
   -e POSTGRES_DB=db \
   -e POSTGRES_USER=usr \
   -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
   -v ./data:/var/lib/postgresql/data \
   -d \
   tp1/db \

docker run \
   --name tp1-adminer \
   --network app-network \
   --rm \
   -p 8080:8080 \
   -d \
   adminer
