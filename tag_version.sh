#!/bin/bash

# Extract version string from pubspec.yaml
X=$(grep '^version:' pubspec.yaml | sed 's/version: //')

# Extract semantic version (x.y.z) from x.y.z+n
VERSION=$(echo $X | cut -d '+' -f1)

# Get Flutter version
FLUTTER_VERSION=$(flutter --version)

# Combine COMMENT from VERSION and FLUTTER_VERSION
COMMENT="$X
$FLUTTER_VERSION"

# echo $COMMENT
# Create annotated git tag
git tag -a "$VERSION" -m "$COMMENT"
