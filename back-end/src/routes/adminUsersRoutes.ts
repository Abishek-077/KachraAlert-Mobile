import { Router } from "express";
import * as usersController from "../controllers/usersController.js";
import { requireAuth, requireAdmin } from "../middleware/auth.js";
import { validateBody } from "../middleware/validate.js";
import { adminCreateUserSchema, adminUpdateUserSchema, adminUpdateUserStatusSchema } from "../dto/adminUserSchemas.js";
import { profileImageUpload } from "../middleware/upload.js";

const router = Router();

router.use(requireAuth, requireAdmin);

router.post("/users", profileImageUpload.single("image"), validateBody(adminCreateUserSchema), usersController.createUser);
router.get("/users", usersController.listUsers);
router.get("/users/:id", usersController.getUser);
router.put(
  "/users/:id",
  profileImageUpload.single("image"),
  validateBody(adminUpdateUserSchema),
  usersController.updateUser
);
router.patch(
  "/users/:id/status",
  validateBody(adminUpdateUserStatusSchema),
  usersController.updateUserStatus
);
router.delete("/users/:id", usersController.deleteUser);

export default router;
