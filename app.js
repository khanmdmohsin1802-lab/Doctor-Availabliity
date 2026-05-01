import "dotenv/config";
import express from "express";
import mongoose from "mongoose";
import http from "http";
import { Server } from "socket.io";

//Route imports
import authRoutes from "./backend/routes/authRoutes.js";
import patientRoutes from "./backend/routes/patientRoutes.js";
import doctorRoutes from "./backend/routes/doctorRoutes.js";

//create instance of Express
const app = express();

// middleware to parse input data into Javascript Object
app.use(express.json());

const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PATCH", "PUT"],
  },
});

app.set("io", io);

io.on("connection", (socket) => {
  console.log(`⚡ A device connected: ${socket.id}`);

  socket.on("disconnect", () => {
    console.log(`❌ A device disconnected: ${socket.id}`);
  });
});

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
    server.listen(8001, () => console.log("Server is running"));
  })
  .catch((error) => {
    console.log("MongoDB connection Error", error);
  });
