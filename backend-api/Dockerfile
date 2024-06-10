### Build stage
# Pulling base image
FROM maven:3.9.7-amazoncorretto-21 AS build

# Setting working directory with vars to be used in next stage
ENV MYAPP_HOME /opt/myapp
WORKDIR $MYAPP_HOME

# Copying sources
COPY pom.xml .
COPY src ./src

# Building application
RUN mvn package -DskipTests


### Run stage
# Pulling base image
FROM eclipse-temurin:21-jre-alpine

# Setting working directory with vars
ENV MYAPP_HOME /opt/myapp
WORKDIR $MYAPP_HOME

# Getting package from build stage
COPY --from=build $MYAPP_HOME/target/*.jar $MYAPP_HOME/app.jar

# Running application
ENTRYPOINT ["java", "-jar", "app.jar"]
