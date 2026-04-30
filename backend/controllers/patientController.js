import User from "../models/User.js";
import Queue from "../models/Queue.js";
import Doctor from "../models/Doctor.js";

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
    const exsistingQueue = await Queue.findOne({
      patientId: req.user._id,
      doctorId: doctor,
      status: "waiting",
    });

    console.log(exsistingQueue);

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

// get Live Queue status
const getLiveQueue = async (req, res) => {
  try {
    const patientId = req.user._id;

    // get the patient appointemt details and doctor he is current appointed at
    const currentTicket = await Queue.findOne({
      patientId: patientId,
      status: "waiting",
      //   uses .populate basically like join
    }).populate("doctorId", "name specialty"); // also store doctors name and specialty for more info

    //  if currentTicket is empty means patient hasn't booked any appointments
    if (!currentTicket) {
      return res.status(404).json({
        success: false,
        message: "You are not currently waiting in a queue",
      });
    }

    const safeDoctorId = currentTicket.doctorId._id || currentTicket.doctorId;

    console.log(
      "Looking for people ahead of ticket created at:",
      currentTicket.createdAt,
    );
    console.log("Doctor ID we are searching for:", safeDoctorId);

    // get count of how many people are ahead
    const peopleAhead = await Queue.countDocuments({
      doctorId: currentTicket.doctorId,
      status: "waiting",
      createdAt: { $lt: new Date(currentTicket.createdAt) },
    });

    console.log(peopleAhead);
    //  formulas to calculate estimated time
    const currentPosition = peopleAhead + 1;
    const avgCheckUpTime = 15;
    const estimatedWaitTime = currentPosition * avgCheckUpTime;

    res.status(200).json({
      succcess: true,
      data: {
        doctorName: currentTicket.doctorId.name,
        doctorSpecialty: currentTicket.doctorId.specialty,
        postion: currentPosition,
        peopleAhead: peopleAhead,
        avgCheckUpTime: avgCheckUpTime,
        estimatedWaitTime: estimatedWaitTime,
        joinedAt: currentTicket.createdAt,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};

const getPatientProfile = async (req, res) => {
  try {
    const patientId = req.user._id;

    const profile = await User.findById(patientId).select("-password");

    if (!profile) {
      return res
        .status(404)
        .json({ success: false, message: "User not found" });
    }

    const history = await Queue.find({ patientId: patientId })
      .populate("doctorId", "name speciality")
      .sort({ createdAt: -1 });

    if (history.length === 0) {
      return res.status(200).json({
        success: true,
        message: "You have not Booked Any Appointments from our App",
        data: {
          profile: profile,
          history: [],
        },
      });
    }

    res.status(200).json({
      profile: profile,
      history: history,
    });
  } catch (error) {
    console.log(error.message);
    res.status(500).json({
      success: false,
      error: error,
    });
  }
};

export {
  getDoctors,
  getDoctorInfoById,
  handleJoinQueue,
  getLiveQueue,
  getPatientProfile,
};
