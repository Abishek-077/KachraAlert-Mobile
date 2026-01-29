import { Router } from "express";
import * as reportsController from "../controllers/reportsController.js";
import { requireAuth, requireAdmin } from "../middleware/auth.js";
import { validateBody } from "../middleware/validate.js";
import { createReportSchema, updateReportSchema, addAttachmentSchema } from "../dto/reportSchemas.js";

const router = Router();

router.get("/", requireAuth, reportsController.listReports);
router.get("/:id", requireAuth, reportsController.getReport);
router.get("/:id/attachments/:attachmentId", requireAuth, reportsController.getReportAttachment);
router.post("/", requireAuth, validateBody(createReportSchema), reportsController.createReport);
router.post("/:id/attachments", requireAuth, validateBody(addAttachmentSchema), reportsController.addReportAttachment);
router.patch("/:id", requireAuth, requireAdmin, validateBody(updateReportSchema), reportsController.updateReport);

export default router;
