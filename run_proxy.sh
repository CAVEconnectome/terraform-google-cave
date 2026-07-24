docker run -d \
  --name local-port-forward \
  -p 8088:80 \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
  nginx