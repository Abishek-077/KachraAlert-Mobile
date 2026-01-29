import type { Server as HttpServer } from "http";
import { Server } from "socket.io";
import { env } from "../config/env.js";
import { verifyAccessToken } from "./jwt.js";

let io: Server | null = null;

export function initSocket(server: HttpServer) {
  io = new Server(server, {
    cors: {
      origin: env.frontendUrl,
      credentials: true
    }
  });

  io.use((socket, next) => {
    const token = socket.handshake.auth?.token as string | undefined;
    if (!token) {
      return next(new Error("Unauthorized"));
    }
    try {
      const payload = verifyAccessToken(token);
      socket.data.user = payload;
      return next();
    } catch {
      return next(new Error("Unauthorized"));
    }
  });

  return io;
}

export function getIo() {
  if (!io) {
    throw new Error("Socket.io server has not been initialized");
  }
  return io;
}
