#!/bin/bash
set -e

echo "==> Spendly: Starting Vercel Flutter Web build..."

# 1. Install Flutter SDK if not already present
if [ ! -d "$HOME/flutter" ]; then
  echo "==> Cloning Flutter SDK (stable branch)..."
  git clone -b stable https://github.com/flutter/flutter.git --depth 1 "$HOME/flutter"
fi

# 2. Add Flutter to PATH
export PATH="$PATH:$HOME/flutter/bin"

echo "==> Flutter SDK version:"
flutter --version

# 3. Enable Web build support
flutter config --enable-web

# 4. Ensure firebase_options.dart exists for compiling
if [ ! -f "lib/firebase_options.dart" ]; then
  echo "==> lib/firebase_options.dart not found in repository. Creating from template for Mock Mode build..."
  cp lib/firebase_options.dart.example lib/firebase_options.dart
fi

# 5. Fetch project dependencies
echo "==> Running flutter pub get..."
flutter pub get

# 6. Build production Web release
echo "==> Compiling Flutter Web for release (base-href=/)..."
flutter build web --release --base-href /

echo "==> Build complete! Output successfully generated at build/web"
