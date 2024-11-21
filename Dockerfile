# Stage 1: Build the application
FROM maven:3.9.4-eclipse-temurin-17 as builder

# Set working directory
WORKDIR /app

# Copy Maven configuration and source code
COPY pom.xml ./
COPY src ./src

# Build the application
RUN mvn package -DskipTests

# Stage 2: Create runtime image
FROM amazoncorretto:17

# Set working directory
WORKDIR /app

# Copy JAR from build stage
COPY --from=builder /app/target/imagegenerator-0.0.1-SNAPSHOT.jar app.jar

# Set environment variable for SQS URL
ENV SQS_QUEUE_URL="https://sqs.eu-west-1.amazonaws.com/244530008913/lambda_sqs_queue"

# Run the Java application
ENTRYPOINT ["java", "-jar", "app.jar"]
