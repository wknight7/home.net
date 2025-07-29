#!/bin/sh

# Minimal Alpine Linux Bootstrap Script - Phase 1
# This works with a fresh Alpine container that has minimal packages

# Update package manager and install essential tools first
apk update
apk add --no-cache curl sudo

# Now download and run the full bootstrap
curl -s http://192.168.86.83/bootstrap-alpine-full.sh | sh
