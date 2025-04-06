#!/bin/bash

# Install Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable

# Add flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Check flutter version
flutter --version

# Get dependencies
flutter pub get

# Build web
flutter build web