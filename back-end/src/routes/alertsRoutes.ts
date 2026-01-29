import { Router } from "express";
import * as alertsController from "../controllers/alertsController.js";
import { requireAuth, requireAdmin } from "../middleware/auth.js";
import { validateBody } from "../middleware/validate.js";
import { broadcastAlertSchema } from "../dto/alertSchemas.js";

const router = Router();

router.get("/", requireAuth, alertsController.listAlerts);
router.post("/broadcast", requireAuth, requireAdmin, validateBody(broadcastAlertSchema), alertsController.broadcastAlert);
router.post("/read-all", requireAuth, alertsController.markAllRead);
router.post("/:id/read", requireAuth, alertsController.markRead);

export default router;
