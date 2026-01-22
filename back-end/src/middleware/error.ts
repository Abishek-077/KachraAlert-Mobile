import type { Request, Response, NextFunction } from "express";
import { ZodError } from "zod";
import { AppError } from "../utils/errors.js";
import { sendError } from "../utils/response.js";

export function errorHandler(err: unknown, _req: Request, res: Response, _next: NextFunction) {
  if (err instanceof ZodError) {
    const message = err.issues[0]?.message ?? "Validation error";
    return sendError(res, message, 400, "VALIDATION_ERROR");
  }

  if (err instanceof AppError) {
    return sendError(res, err.message, err.statusCode, err.errorCode);
  }

  console.error(err);
  return sendError(res, "Unexpected server error", 500, "SERVER_ERROR");
}
