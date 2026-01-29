import type { Request } from "express";
import { env } from "../config/env.js";

export function toPublicUrl(req: Request, url?: string | null) {
  if (!url) {
    return null;
  }

  if (url.startsWith("http://") || url.startsWith("https://")) {
    return url;
  }

  const baseUrl = env.publicBaseUrl ?? `${req.protocol}://${req.get("host")}`;
  if (!baseUrl) {
    return url;
  }

  const normalizedPath = url.startsWith("/") ? url : `/${url}`;
  return `${baseUrl}${normalizedPath}`;
}
