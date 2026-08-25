FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies.
#
# The lockfile is resolved from scratch inside the image on purpose. npm does
# not install the platform-specific optional dependency recorded in the
# committed lockfile (npm/cli#4828): both `npm install` and `npm ci` leave
# node_modules/@rollup empty on this image, and Vite then dies at startup with
#   Error: Cannot find module @rollup/rollup-linux-x64-musl
# Re-resolving picks the correct rollup binary for whatever architecture the
# image is built on, instead of hard-coding one platform's package name.
RUN rm -f package-lock.json && npm install

# Copy the rest of the application
COPY . .

# Expose port
EXPOSE 5173

# Start the development server
CMD ["npm", "run", "dev", "--", "--host"]