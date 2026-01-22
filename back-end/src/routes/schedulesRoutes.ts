import { Router } from "express";
import * as schedulesController from "../controllers/schedulesController.js";
import { requireAdmin, requireAuth } from "../middleware/auth.js";
import { validateBody } from "../middleware/validate.js";
import { createScheduleSchema, updateScheduleSchema } from "../dto/scheduleSchemas.js";

const router = Router();

router.get("/", requireAuth, schedulesController.listSchedules);
router.post("/", requireAuth, requireAdmin, validateBody(createScheduleSchema), schedulesController.createSchedule);
router.patch("/:id", requireAuth, requireAdmin, validateBody(updateScheduleSchema), schedulesController.updateSchedule);
router.delete("/:id", requireAuth, requireAdmin, schedulesController.deleteSchedule);

export default router;
