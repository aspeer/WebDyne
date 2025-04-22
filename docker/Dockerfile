FROM alpine:latest

# Set the working directory in the container
WORKDIR /app

# Copy the local binary to the container
#COPY webdyne.psgi.pp /app/webdyne.psgi.pp
COPY --chmod=755 ./webdyne.psgi.pp /app/webdyne.psgi.pp
COPY --chmod=644 ./server_time.psp /app/server_time.psp

# Expose port 5000
EXPOSE 5000

# Set an environment variable (can be overridden at runtime)
ENV DOCUMENT_ROOT=~

# Run the binary with the environment variable
CMD ["/app/webdyne.psgi.pp", "/app/server_time.psp"]

