import express from "express";
import { protect, authorizeRoles } from "../middlewares/authMilddleware.js";
import { getDoctorQueue } from "../controllers/doctorController.js";

const router = express.Router();

// auth middlewares -
router.use(protect);
router.use(authorizeRoles("doctor"));

// dashboard routes -
router.get("/dashboard/queue", getDoctorQueue);

export default router;
