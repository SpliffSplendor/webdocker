#!/bin/bash
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
docker build --file ./Dockerfile -t webdocker:${TIMESTAMP} -t webdocker:latest .
