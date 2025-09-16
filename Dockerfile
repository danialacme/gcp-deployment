# Step 1: Build React app
FROM node:18 AS build
WORKDIR /app

# Copy manifest files
COPY package*.json ./

# Install dependencies (ci ensures reproducibility with lockfile)
RUN npm ci --no-audit --no-fund

# Copy the rest of the app
COPY . .

# Build production React app
RUN npm run build

# Step 2: Serve with nginx
FROM nginx:stable-alpine

# Copy build artifacts to nginx html folder
COPY --from=build /app/build /usr/share/nginx/html

# Optional: custom nginx config for React Router
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]