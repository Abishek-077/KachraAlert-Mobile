import { Router } from "express";
import * as usersController from "../controllers/usersController.js";
import { requireAuth, requireAdmin } from "../middleware/auth.js";
import { validateBody } from "../middleware/validate.js";
import { updateProfileSchema, uploadProfileImageSchema } from "../dto/userSchemas.js";

const router = Router();

router.get("/me", requireAuth, usersController.getMe);
router.patch("/me", requireAuth, validateBody(updateProfileSchema), usersController.updateMe);
router.post("/me/profile-image", requireAuth, validateBody(uploadProfileImageSchema), usersController.uploadProfileImage);
router.get("/", requireAuth, requireAdmin, usersController.listUsers);
router.get("/:id", requireAuth, requireAdmin, usersController.getUser);
router.get("/:id/profile-image", requireAuth, usersController.getProfileImage);

export default router;
