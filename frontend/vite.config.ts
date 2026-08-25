import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    host: "0.0.0.0",
    port: 5173,
    watch: {
      // The source directory is a bind mount. Filesystem events are not
      // delivered across that boundary on Docker Desktop for Windows and
      // macOS, so chokidar's native watcher never fires and Vite keeps
      // serving the module it transformed at boot -- edits appear to do
      // nothing until the container is restarted. Polling costs a little
      // idle CPU and makes hot reload work for everyone.
      usePolling: true,
      interval: 300,
    },
  },
});
