import { z } from "zod";

export const broadcastAlertSchema = z.object({
  title: z.string().min(3, "Title is required"),
  body: z.string().min(3, "Body is required"),
  severity: z.enum(["info", "warning", "urgent"]).optional(),
  target: z.string().optional()
});
