#!/bin/bash
# CLAWN PRIME - Linux Setup Script

set -e

echo "==================================="
echo "  CLAWN PRIME - Linux Setup"
echo "==================================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Flutter not found. Installing..."
    
    # Clone Flutter
    if [ ! -d "$HOME/flutter" ]; then
        git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
    fi
    
    # Add to PATH
    export PATH="$PATH:$HOME/flutter/bin"
    
    # Add to bashrc if not already there
    if ! grep -q "flutter/bin" ~/.bashrc; then
        echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
    fi
    
    echo "Flutter installed. Run: source ~/.bashrc"
fi

# Check Flutter version
echo "Checking Flutter..."
flutter doctor

# Install Linux dependencies
echo ""
echo "Installing Linux dependencies..."
sudo apt update
sudo apt install -y \
    cmake ninja-build clang pkg-config \
    libgtk-3-dev \
    liblzma-dev libstdc++-12-dev \
    libpulse-dev \
    gettext \
    libasound2-dev

# Install project dependencies
echo ""
echo "Installing project dependencies..."
flutter pub get

# Create .env if it doesn't exist
if [ ! -f ".env" ]; then
    echo ""
    echo "Creating .env file..."
    cp .env.example .env
    echo "Please edit .env and add your Gemini API key"
    echo "Get one at: https://aistudio.google.com/apikey"
fi

echo ""
echo "==================================="
echo "  Setup Complete!"
echo "==================================="
echo ""
echo "To run the app:"
echo "  flutter run -d linux"
echo ""
echo "To build for production:"
echo "  flutter build linux --release"
echo ""
echo "Don't forget to:"
echo "  1. Edit .env and add your API key"
echo "  2. Run 'source ~/.bashrc' if Flutter was just installed"
echo ""
