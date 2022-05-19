FROM node:16-alpine

RUN apk --no-cache add openssh g++ gcc git libgcc libstdc++ linux-headers make python3 libexecinfo-dev

WORKDIR /app

# first package manager stuff so installing is cached by Docker.
ADD package.json /app/package.json
ADD package-lock.json /app/package-lock.json
RUN npm ci

ADD . /app

RUN mkdir build
ENV DIST_BUILD 1
RUN node -r ts-node/register scripts/build.ts german
RUN node -r ts-node/register scripts/build.ts english
RUN node -r ts-node/register scripts/build.ts chinese

FROM nginx:1.21

WORKDIR /usr/share/nginx/html

COPY --from=0 /app/build /usr/share/nginx/html
ADD src/index.html /usr/share/nginx/html/index.html

RUN echo 'server {\
            listen $PORT default_server;\
            location / {\
              root   /usr/share/nginx/html;\
              index  index.html index.htm;\
            }\
          }' > /etc/nginx/conf.d/default.conf.template
CMD /bin/bash -c "envsubst '\$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf" && nginx -g 'daemon off;'
