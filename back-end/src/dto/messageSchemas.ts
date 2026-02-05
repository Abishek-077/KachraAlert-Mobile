import { z } from "zod";

export const sendMessageSchema = z.object({
  body: z.string().trim().min(1, "Message body is required").max(1000, "Message is too long")
});
