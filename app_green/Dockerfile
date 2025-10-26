# ./app_blue/Dockerfile (same for app_green)
FROM node:18-alpine

WORKDIR /app

# Copy package files first for caching
COPY package*.json ./

RUN npm install --production

# Copy app source
COPY . .

EXPOSE 8080

CMD ["node", "app.js"]
