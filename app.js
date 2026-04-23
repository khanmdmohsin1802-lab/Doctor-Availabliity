import express from "express";
import mongoose from "mongoose";
import dotenv from "dotenv";

//Route imports
import authRoutes from "./backend/routes/authRoutes.js";
import patientRoutes from "./backend/routes/patientRoutes.js";
import doctorRoutes from "./backend/routes/doctorRoutes.js";

dotenv.config();

//create instance of Express
const app = express();

// middleware to parse input data into Javascript Object
app.use(express.json());

// every route starting with api/v1/auth go to routes/authRoutes.js and triger the register or login route
app.use("/api/v1/auth", authRoutes);
app.use("/api/v1/patients", patientRoutes);
app.use("/api/v1/doctor", doctorRoutes);

mongoose
  .connect(process.env.MONGO_URI)
  .then(() => {
    console.log("MongoDB server connected");
    app.listen(3000, () => console.log("Server is running"));
  })
  .catch((error) => {
    console.log("MongoDB connection Error", error);
  });
