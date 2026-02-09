import type { Server as HttpServer } from "http";
import { Server } from "socket.io";
import { env } from "../config/env.js";
import { verifyAccessToken, type AccessTokenPayload } from "./jwt.js";
import { sendMessage, type ChatMessage } from "../services/messageService.js";

let io: Server | null = null;

type SendMessagePayload = {
  recipientId?: string;
  body?: string;
  replyToMessageId?: string;
};

type SendMessageAck = {
  success: boolean;
  data?: ChatMessage;
  error?: string;
};

function getUserRoom(userId: string) {
  return `user:${userId}`;
}

export function emitChatMessage(message: ChatMessage) {
  if (!io) return;
  io.to(getUserRoom(message.senderId)).emit("messages:new", message);
  io.to(getUserRoom(message.recipientId)).emit("messages:new", message);
}

export function emitChatMessageUpdate(message: ChatMessage) {
  if (!io) return;
  io.to(getUserRoom(message.senderId)).emit("messages:updated", message);
  io.to(getUserRoom(message.recipientId)).emit("messages:updated", message);
}

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

  io.on("connection", (socket) => {
    const socketUser = socket.data.user as AccessTokenPayload;
    socket.join(getUserRoom(socketUser.sub));

    socket.on(
      "messages:send",
      async (payload: SendMessagePayload, callback?: (response: SendMessageAck) => void) => {
        try {
          const message = await sendMessage({
            senderId: socketUser.sub,
            recipientId: payload?.recipientId ?? "",
            body: payload?.body ?? "",
            replyToMessageId: payload?.replyToMessageId
          });
          emitChatMessage(message);
          if (callback) {
            callback({ success: true, data: message });
          }
        } catch (error) {
          if (callback) {
            callback({
              success: false,
              error: error instanceof Error ? error.message : "Unable to send message"
            });
          }
        }
      }
    );
  });

  return io;
}

export function getIo() {
  if (!io) {
    throw new Error("Socket.io server has not been initialized");
  }
  return io;
}
