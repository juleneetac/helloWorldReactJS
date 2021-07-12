# # Stage 0, "build-stage", based on Node.js, to build and compile the frontend
# FROM tiangolo/node-frontend:10 as build-stage
# WORKDIR /app
# COPY package*.json ./
# RUN ls /app
# RUN npm install
# COPY . .
# RUN npm run build

# # Stage 1, based on Nginx, to have only the compiled app, ready for production with Nginx
# # FROM nginx:1.15
# # USER root
# # RUN chgrp -R root /var/cache/nginx /var/run /var/log/nginx && \
# #     chmod -R 770 /var/cache/nginx /var/run /var/log/nginx /var/log
# # RUN chmod 666 /etc/nginx/nginx.conf
# # COPY --from=build-stage /app/build/ /usr/share/nginx/html
# # EXPOSE 8400
# # CMD ["nginx", "-g", "daemon off;"]
# # Copy the default nginx.conf provided by tiangolo/node-frontend
# #COPY --from=build-stage /nginx.conf /etc/nginx/conf.d/default.conf

# FROM nginx:1.15.2-alpine
# RUN ls /var/www
# COPY ./build /var/www

# COPY nginx.conf /etc/nginx/nginx.conf
# EXPOSE 80
# ENTRYPOINT ["nginx","-g","daemon off;"]

FROM nginx:1.17.3

RUN rm /etc/nginx/conf.d/*
RUN mkdir /tmp/nginx
RUN mkdir -p /var/log/app
RUN chmod -R 777 /tmp/nginx

#este copi he puesto el build/.
COPY build/. /opt/app    
COPY nginx.conf /etc/nginx/nginx.conf
USER root
RUN chgrp -R root /var/cache/nginx /var/run /var/log/nginx && \
    chmod -R 770 /var/cache/nginx /var/run /var/log/nginx /var/log
RUN chmod 666 /etc/nginx/nginx.conf
RUN apt-get update && apt-get install -y vim
