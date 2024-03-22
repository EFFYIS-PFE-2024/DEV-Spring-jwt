# syntax=docker/dockerfile:experimental
FROM eclipse-temurin:17-jdk-alpine as build
WORKDIR /workspace/app

COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY src src

# Grant execute permission to mvnw
RUN chmod +x mvnw

# Set DOCKER_BUILDKIT=1 for this build stage
# This enables Docker BuildKit only for this stage
# It doesn't affect other stages or subsequent builds
RUN --mount=type=cache,target=/root/.m2 \
    export DOCKER_BUILDKIT=1 \
    && ./mvnw install -DskipTests
RUN mkdir -p target/dependency && (cd target/dependency; jar -xf ../*.jar)

FROM eclipse-temurin:17-jdk-alpine
VOLUME /tmp
ARG DEPENDENCY=/workspace/app/target/dependency
COPY --from=build ${DEPENDENCY}/BOOT-INF/lib /app/lib
COPY --from=build ${DEPENDENCY}/META-INF /app/META-INF
COPY --from=build ${DEPENDENCY}/BOOT-INF/classes /app
COPY /src/main/java/com/jihad/springjwt/ /app/com/jihad/springjwt/

WORKDIR /app

ENTRYPOINT ["java", "-cp", ".:/app/lib/*", "com.jihad.springjwt.SpringBootSecurityJwtApplication"]
