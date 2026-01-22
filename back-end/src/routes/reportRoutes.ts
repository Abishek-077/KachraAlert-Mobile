import { Router } from "express";
import * as reportsController from "../controllers/reportsController.js";
import { requireAuth, requireAdmin } from "../middleware/auth.js";
import { validateBody } from "../middleware/validate.js";
import { createReportSchema, updateReportSchema } from "../dto/reportSchemas.js";

const router = Router();

router.get("/", requireAuth, reportsController.listReports);
router.get("/:id", requireAuth, reportsController.getReport);
router.post("/", requireAuth, validateBody(createReportSchema), reportsController.createReport);
router.patch("/:id", requireAuth, requireAdmin, validateBody(updateReportSchema), reportsController.updateReport);

export default router;
