FROM nginx:latest

LABEL maintainer="web-docker"

RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY nginx.conf /etc/nginx/nginx.conf

COPY html/ /usr/share/nginx/html/

RUN mkdir -p /var/log/nginx && \
    mkdir -p /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /var/cache/nginx

EXPOSE 80
EXPOSE 443

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

USER nginx

CMD ["nginx", "-g", "daemon off;"]