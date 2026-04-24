import User from "../models/User.js";
import Queue from "../models/Queue.js";

const getDoctors = async (req, res) => {
  try {
    // get required data from the query ---> (work of frontend)
    const { search, specialty, page = 1, limit = 5 } = req.query;

    // create an object
    let query = { role: "doctor" };

    if (search) {
      /* add this in the query object 
       query = {
                role : "doctor", 
                name: { $regex: 'moh', $options: 'i' } 
               }
     */
      query.name = { $regex: search, $option: i };
    }

    // same as query.name
    if (specialty) {
      query.specialty = specialty;
    }

    // Hardcap the Limit --> just incase if the hacker tries to chnage limit=10000 and freeze the database
    let limitNum = parseInt(limit) || 5;
    if (limitNum > 10) limitNum = 10;

    const skipIndex = (page - 1) * limitNum;

    // store all of the doctors that satisfies the query
    const doctors = await User.find(query)
      .select("-password") // remove password for security
      .limit(limitNum)
      .skip(skipIndex)
      .sort({ createdAt: -1 });

    // get the number of total item as per the query to determine Total Pages
    const totalDoctors = await User.countDocuments(query);

    res.status(200).json({
      success: true,
      data: doctors,
      pagination: {
        total: totalDoctors,
        currrentPage: parseInt(page),
        totalPages: totalDoctors / limitNum,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get doctor Information
const getDoctorInfoById = async (req, res) => {
  try {
    // get doctor Id
    const doctorId = req.params.id;

    // get the doctor Info but remove password for security
    const doctor = await User.findById(doctorId).select("-password");

    // Check if such doctor exsist and also confirm it's role as a doctor
    if (!doctor || doctor.role != "doctor") {
      return res.status(404).json({
        success: false,
        message: "Doctor Not Found",
      });
    }

    // if everything fine send the response for the frontend 
    res.status(200).json({
      success: true,
      data: doctor,
    });
  } catch (error) {
    console.log(error.message);
    res.staus(500).json({ success: false, message: "Internal Server Error" });
  }
};

// function to join a Queue
const handleJoinQueue = async (req, res) => {
  try {
    // get the inputs 
    const { doctorId, reasonForVisit } = req.body;

    // get the patient's Id using req.user._id (from the auth controller)
    const patientId = req.user._id;

    // get the doctor user wants to book the appointment of
    const doctor = await User.findById(doctorId);

    // check if such doctor exsist and also confirm if the role is doctor
    if (!doctor || doctor.role != "doctor") {
      return res
        .status(404)
        .json({ success: false, message: "Doctor Not Found" });
    }

    // check the status of doctor (currently accepting or not)
    if (!doctor.isAcceptingPatients) {
      return res.status(400).json({
        success: false,
        message: "Doctor is NOT currently Accepting any Patients",
      });
    }

    // check if the user is already in the queue to avoid spam
    const exsistingQueue = await User.findOne({
      patientId,
      doctorId,
      status: "waiting",
    });

    //  give the response Bad Request for existing Queue
    if (exsistingQueue) {
      return res.status(400).json({
        success: false,
        message: "You are Already Waiting in the Queue",
      });
    }
    //  when everything correct create a new queue 
    const newQueueEntry = await Queue.create({
      patientId,
      doctorId,
      reasonForVisit: reasonForVisit || "Genral consultation",
      status: "waiting",
    });

    // give the successful response and the data for the frontend
    res.status(201).json({
      success: true,
      message: `You are in the waitlist of doctor : ${doctor.name} `,
      data: newQueueEntry,
    });
  } catch (error) {
    res.status(500).json({
      succcess: false,
      error: error.message,
    });
  }
};

export { getDoctors, getDoctorInfoById, handleJoinQueue };
