FROM nginx:1.17.3


RUN rm /etc/nginx/conf.d/*
RUN mkdir /tmp/nginx
RUN mkdir -p /var/log/app
RUN chmod -R 777 /tmp/nginx

COPY public/react-nginx-docker/. /opt/app
COPY nginx.conf /etc/nginx/nginx.conf
USER root
RUN chgrp -R root /var/cache/nginx /var/run /var/log/nginx && \
    chmod -R 770 /var/cache/nginx /var/run /var/log/nginx /var/log
RUN chmod 666 /etc/nginx/nginx.conf
RUN apt-get update && apt-get install -y vim
