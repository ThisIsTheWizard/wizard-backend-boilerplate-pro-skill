import 'dotenv/config';
import { createApp } from './app.js';

const PORT = parseInt(process.env.PORT ?? '3000', 10);
const app = createApp();

const server = app.listen(PORT, () => {
  console.log(`my-api running on http://localhost:${PORT}`);
  console.log(`Swagger UI: http://localhost:${PORT}/docs`);
});

const shutdown = () => {
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
};

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
