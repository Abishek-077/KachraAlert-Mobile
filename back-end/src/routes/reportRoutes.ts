import { Router } from "express";
import * as reportsController from "../controllers/reportsController.js";
import { requireAuth } from "../middleware/auth.js";
import { validateBody } from "../middleware/validate.js";
import { createReportSchema, updateReportSchema } from "../dto/reportSchemas.js";
import { uploadReportAttachment } from "../config/upload.js";

const router = Router();

router.get("/", requireAuth, reportsController.listReports);
router.get("/:id", requireAuth, reportsController.getReport);
router.post(
  "/",
  requireAuth,
  uploadReportAttachment.single("attachment"),
  validateBody(createReportSchema),
  reportsController.createReport
);
router.patch("/:id", requireAuth, validateBody(updateReportSchema), reportsController.updateReport);
router.delete("/:id", requireAuth, reportsController.deleteReport);

export default router;
