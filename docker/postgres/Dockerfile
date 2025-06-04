# Use the official PostgreSQL base image
FROM postgres:15

# Set environment variables for PostgreSQL
ENV POSTGRES_USER=amcloud_admin
ENV POSTGRES_PASSWORD=amcloud_pass

# Copy initialization scripts into the container
COPY init-scripts/ /docker-entrypoint-initdb.d/

# Expose the PostgreSQL port
EXPOSE 5432
