FROM debian:bookworm-slim

# Install build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    cmake \
    gettext \
    libgd-dev \
    libusb-1.0-0-dev \
    git \
    make \
    && rm -rf /var/lib/apt/lists/*

# Clone and build ptouch-print
WORKDIR /build
RUN git clone https://git.familie-radermacher.ch/linux/ptouch-print.git && \
    cd ptouch-print && \
    ./build.sh

# Install ptouch-print
RUN cd ptouch-print && \
    mkdir -p /usr/local/bin /usr/local/share/man/man1 && \
    cp build/ptouch-print /usr/local/bin/ && \
    cp ptouch-print.1 /usr/local/share/man/man1/ && \
    chmod +x /usr/local/bin/ptouch-print

# Set up working directory
WORKDIR /workspace

# Default command - run ptouch-print with any arguments
ENTRYPOINT ["/usr/local/bin/ptouch-print"]
CMD ["--help"]


