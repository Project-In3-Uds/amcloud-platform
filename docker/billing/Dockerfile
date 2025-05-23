# Use an OpenJDK base image
FROM openjdk:17-jdk-slim

# Set the working directory
WORKDIR /app

# Copy the JAR file into the container
COPY target/billing-0.0.1-SNAPSHOT.jar app.jar

# Expose the port used by the service
# EXPOSE 8082

# Set environment variables
# ENV SPRING_PROFILES_ACTIVE=prod

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
