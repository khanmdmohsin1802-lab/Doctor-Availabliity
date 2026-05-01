import express from "express";
import { protect, authorizeRoles } from "../middlewares/authMilddleware.js";
import {
  getDoctorQueue,
  handleNextPatient,
  acceptingPatientsToggle,
} from "../controllers/doctorController.js";

const router = express.Router();

// auth middlewares -
router.use(protect);
router.use(authorizeRoles("doctor"));

// dashboard routes -
router.get("/dashboard/queue", getDoctorQueue);

router.patch("/queue/next", handleNextPatient);

router.patch("/status/toggle", acceptingPatientsToggle);

export default router;
