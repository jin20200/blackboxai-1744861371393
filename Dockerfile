# Use Node.js LTS version
FROM node:18-alpine

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
# Copy package.json and package-lock.json first for better caching
COPY backend/package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy app source
COPY backend/ .

# Create volume for MongoDB data
VOLUME ["/data/db"]

# Expose ports
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production

# Start the application
CMD ["npm", "start"]
