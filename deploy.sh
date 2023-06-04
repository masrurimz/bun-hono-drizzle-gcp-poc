#!/bin/bash

IMAGE="europe-west3-docker.pkg.dev/hono-drizzle/docker-registry/app"


docker build -t "$IMAGE:latest" .
docker push "$IMAGE:latest"
gcloud run deploy hono-app --image "$IMAGE:latest" --region europe-west3