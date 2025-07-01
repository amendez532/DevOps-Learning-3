# Use official Node.js LTS image (Alpine for small size)
FROM node:18-alpine

# Create app directory
WORKDIR /usr/src/app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install app dependencies in production mode
RUN npm install --production

# Copy app source code
COPY App/ .

# Expose port 80 to match your Terraform configuration
EXPOSE 80

# If your app listens on process.env.PORT, you can keep this as is.
# Otherwise, ensure your app binds to port 80 explicitly.

# Start the app
CMD ["npm", "start"]
