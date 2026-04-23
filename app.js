import "dotenv/config";
import express from "express";
import mongoose from "mongoose";

//Route imports
import authRoutes from "./backend/routes/authRoutes.js";
import patientRoutes from "./backend/routes/patientRoutes.js";
import doctorRoutes from "./backend/routes/doctorRoutes.js";

//create instance of Express
const app = express();

// middleware to parse input data into Javascript Object
app.use(express.json());

// every route starting with api/v1/auth go to routes/authRoutes.js and triger the register or login route
app.use("/api/v1/auth", authRoutes);
app.use("/api/v1/patients", patientRoutes);
app.use("/api/v1/doctors", doctorRoutes);

// Mongoose database connection
mongoose
  .connect(process.env.MONGO_URI)
  .then(() => {
    console.log("MongoDB server connected");

    //Server spin up
    app.listen(3000, () => console.log("Server is running"));
  })
  .catch((error) => {
    console.log("MongoDB connection Error", error);
  });
