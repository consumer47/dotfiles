# Mopidy Docker Setup

A complete, isolated Mopidy setup with Python 3.11, Spotify (v5.0.0a4), Iris, and YouTube.

## Features

- ✅ Python 3.11 (supports latest Mopidy-Spotify)
- ✅ Mopidy-Spotify v5.0.0a4 with playback support
- ✅ Iris web interface
- ✅ YouTube support
- ✅ Isolated from system/snap conflicts
- ✅ PulseAudio integration

## Setup

1. **Build and start:**
   ```bash
   cd ~/dotfiles/mopidy/docker
   docker-compose up -d
   ```

2. **Access Iris:**
   Open http://localhost:6680/iris/

3. **View logs:**
   ```bash
   docker-compose logs -f
   ```

4. **Stop:**
   ```bash
   docker-compose down
   ```

## Configuration

Config is at: `~/dotfiles/mopidy/.config/mopidy/mopidy.conf`

Mopidy will automatically reload when you edit the config.

## Troubleshooting

**No audio?**
- Make sure PulseAudio is running: `pulseaudio --check`
- Check audio devices are accessible: `ls -la /dev/snd`

**Spotify not working?**
- Check your credentials in mopidy.conf
- Make sure you're using OAuth tokens (client_id/client_secret)


