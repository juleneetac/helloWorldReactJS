# FROM node:10
# WORKDIR /usr/src/app
# COPY package*.json ./
# RUN npm install
# COPY . .
# EXPOSE 3000
# CMD [ "npm", "start" ]


# Stage 0, "build-stage", based on Node.js, to build and compile the frontend
FROM tiangolo/node-frontend:10 as build-stage
WORKDIR /app
COPY pack*.json /app/
RUN ls /app
#añadido por mi
#RUN chmod 777 /app/  

RUN npm install
COPY ./ /app/
RUN ls /app
RUN npm run build


# Stage 1, based on Nginx, to have only the compiled app, ready for production with Nginx
FROM nginx:1.15

#añadido por mi
#RUN chmod 777 /usr/share/nginx/

COPY --from=build-stage /app/build/ /usr/share/nginx/html


#añadido por mi
#RUN chmod 666 /etc/nginx/

# Copy the default nginx.conf provided by tiangolo/node-frontend
COPY --from=build-stage /nginx.conf /etc/nginx/conf.d/default.conf
