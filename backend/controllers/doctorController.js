import User from "../models/User.js";
import Queue from "../models/Queue.js";

const getDoctorQueue = async (req, res) => {
  try {
    const doctorId = req.user._id;

    const activeQueue = await Queue.find({
      doctorId: doctorId,
      status: "waiting",
    })
      .populate("patientId", "name age weight email")
      .sort({ createdAt: 1 });

    if (activeQueue.length === 0) {
      return res.status(200).json({
        success: true,
        data: [],
        count: activeQueue.length,
        message: "You currently have no patient in the Queue",
      });
    }

    res.status(200).json({
      success: true,
      data: activeQueue,
      count: activeQueue.length,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

const handleNextPatient = async (req, res) => {
  try {
    const doctorId = req.user._id;

    await Queue.updateOne(
      {
        doctorId: doctorId,
        status: "in-progress",
      },
      { $set: { status: "completed" } },
    );

    const nextPatient = await Queue.findOneAndUpdate(
      {
        doctorId: doctorId,
        status: "waiting",
      },
      { $set: { status: "in-progress" } },
      { sort: { createdAt: 1 }, new: true },
    ).populate("patientId", "name age weight email");

    if (!nextPatient) {
      return res.status(200).json({
        success: true,
        message: "No patient in the Waiting Room, Time for Coffee break",
      });
    }

    res.status(200).json({
      success: true,
      message: `Now seeing ${nextPatient.patientId.name}`,
      data: nextPatient,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export { getDoctorQueue, handleNextPatient };
