FROM node:24-alpine
RUN apk add --no-cache postgresql-client
WORKDIR /app
COPY server.js .
ARG APP_VERSION
ENV APP_VERSION=${APP_VERSION}
USER node
EXPOSE 3000
CMD ["node", "server.js"]
