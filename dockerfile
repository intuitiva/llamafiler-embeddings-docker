# Use Debian stable for llamafiler
FROM debian:stable

# Create a non-root user
RUN addgroup --gid 1000 user && \
    adduser --uid 1000 --gid 1000 --disabled-password --gecos "" user

# Install dependencies and setup APE loader for Actually Portable Executables
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Download and install APE loader for handling Actually Portable Executables
    curl -L -o /usr/bin/ape https://cosmo.zip/pub/cosmos/bin/ape-$(uname -m).elf && \
    chmod +x /usr/bin/ape && \
    # Register APE binary format for llamafiler (Actually Portable Executable)
    echo ':APE:M::MZqFpD::/usr/bin/ape:' > /proc/sys/fs/binfmt_misc/register || true && \
    echo ':APE-jart:M::jartsr::/usr/bin/ape:' > /proc/sys/fs/binfmt_misc/register || true

# Set working directory
WORKDIR /usr/local/bin

# Copy the pre-downloaded llamafiler binary
COPY llamafiler-0.9.3 .
RUN chmod +x llamafiler-0.9.3

# Create models directory and copy the pre-downloaded model
WORKDIR /models
COPY Qwen3-Embedding-0.6B-Q8_0.gguf .

# Switch to the non-root user
USER user

# Set working directory
WORKDIR /usr/local/bin

# Expose port 8080
EXPOSE 8080

# Set entrypoint and default command - use shell wrapper to handle APE binary
ENTRYPOINT ["sh", "-c"]
CMD ["./llamafiler-0.9.3 -m /models/Qwen3-Embedding-0.6B-Q8_0.gguf -l 0.0.0.0:8080"]
