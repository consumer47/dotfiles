#!/bin/bash
# Start Mopidy in Docker with full Spotify support

cd "$(dirname "$0")"

echo "🎵 Starting Mopidy (Docker)..."
echo "   - Python 3.11"
echo "   - Mopidy-Spotify v5.0.0a4"
echo "   - Iris + YouTube"
echo ""

# Stop old systemd service if running
systemctl --user stop mopidy 2>/dev/null || true

# Build if needed and start
docker compose up -d --build

echo ""
echo "✅ Mopidy is running!"
echo ""
echo "📍 Access Iris:  http://localhost:6680/iris/"
echo "📊 View logs:    docker compose logs -f"
echo "🛑 Stop:         docker compose down"
echo ""

