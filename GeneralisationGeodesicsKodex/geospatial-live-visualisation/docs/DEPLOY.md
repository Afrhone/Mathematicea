# Deployment

## Local

```bash
python3 scripts/serve.py 8080
```

## Nginx

```nginx
server {
  listen 80;
  server_name geo.example.test;
  root /srv/geospatial-live-visualisation;
  index index.html;

  location / {
    try_files $uri $uri/ /index.html;
  }
}
```

## Caddy

```caddyfile
geo.example.test {
  root * /srv/geospatial-live-visualisation
  file_server
}
```

## Static copy

The app has no build step. Copy the directory to any static web root.
