#!/bin/bash

# Exit on error
set -e

echo "--- Cloning Flutter SDK (Stable) ---"
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Add flutter to path
export PATH="$PATH:`pwd`/flutter/bin"

echo "--- Flutter Configuration ---"
flutter config --enable-web
flutter doctor

echo "--- Ensuring Web Platform Files ---"
# This recreates the web directory if it's missing or outdated
flutter create . --platforms=web

echo "--- Getting Dependencies ---"
flutter pub get

echo "--- Building for Web ---"
# Using --release and explicitly setting the output directory (default is build/web)
flutter build web --release

echo "--- Build Completed! ---"
