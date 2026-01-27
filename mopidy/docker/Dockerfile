FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-pulseaudio \
    gstreamer1.0-tools \
    gir1.2-gst-plugins-base-1.0 \
    libgirepository1.0-dev \
    gcc \
    libcairo2-dev \
    pkg-config \
    pulseaudio \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Mopidy and extensions  
RUN pip install --no-cache-dir \
    PyGObject \
    mopidy==3.4.2 \
    Mopidy-Iris \
    Mopidy-YouTube

# Note: Spotify playback requires Mopidy 4.x which is still in development
# For now, use YouTube or the web Spotify player

# Create mopidy user
RUN useradd -m -s /bin/bash mopidy && \
    mkdir -p /var/lib/mopidy/.config && \
    chown -R mopidy:mopidy /var/lib/mopidy

USER mopidy
WORKDIR /var/lib/mopidy

# Expose Mopidy HTTP port
EXPOSE 6680

# Run Mopidy
CMD ["mopidy", "--config", "/config/mopidy.conf"]

