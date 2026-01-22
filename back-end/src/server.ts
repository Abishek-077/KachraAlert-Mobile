import mongoose from "mongoose";
import { createServer } from "http";
import app from "./app.js";
import { env } from "./config/env.js";
import { initSocket } from "./utils/socket.js";

async function start() {
  try {
    await mongoose.connect(env.mongoUri);
    console.log("Connected to MongoDB");

    const httpServer = createServer(app);
    initSocket(httpServer);

    httpServer.listen(env.port, () => {
      console.log(`API listening on ${env.port}`);
    });
  } catch (error) {
    console.error("Failed to start server", error);
    process.exit(1);
  }
}

start();
