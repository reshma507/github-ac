FROM node:20-bullseye
 
WORKDIR /app
 
# Copy package files and install dependencies
COPY package.json package-lock.json* ./
RUN npm install
RUN npm install pg --save
 
# Copy the full project
COPY . .
 
# Build Strapi (build TypeScript → dist/)
RUN npm run build
 
EXPOSE 1337
 
# Start Strapi in production mode
CMD ["npm", "run", "start"]
