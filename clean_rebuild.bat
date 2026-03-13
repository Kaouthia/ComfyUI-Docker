docker compose down
docker compose rm -f
docker image rm comfyui:latest
docker builder prune -af
docker compose build --no-cache
docker compose up -d
pause