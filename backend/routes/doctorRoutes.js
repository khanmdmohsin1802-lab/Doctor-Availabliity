import express from "express";
import { protect, authorizeRoles } from "../middlewares/authMilddleware.js";

const router = express.Router();

router.use(protect);
router.use(authorizeRoles("doctor"));

export default router;