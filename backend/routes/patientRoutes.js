import express from "express";
import { protect, authorizeRoles } from "../middlewares/authMilddleware.js";
import {
  getDoctors,
  getDoctorInfoById,
  handleJoinQueue,
  getLiveQueue,
  getPatientProfile,
} from "../controllers/patientController.js";

const router = express.Router();

// authorization middleware
router.use(protect);
router.use(authorizeRoles("patient"));

//  fetch doctor details routes
router.get("/doctors", getDoctors);
router.get("/doctors/:id", getDoctorInfoById);

// patient's profile route
router.get("/profile", getPatientProfile);

// queue realted routes
router.post("/queue/join", handleJoinQueue);
router.get("/queue/status", getLiveQueue);

export default router;
