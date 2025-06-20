import express from "express";
import Stripe from "stripe";
import cors from "cors";
import dotenv from "dotenv";

// Load environment variables
dotenv.config();

const app = express();

// Enable CORS for all routes
app.use(cors());
app.use(express.json());

// Initialize Stripe with test secret key
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

// Health check endpoint
app.get("/", (req, res) => {
  res.json({ status: "Server is running" });
});

app.post("/createPaymentIntent", async (req, res) => {
  console.log("Received request:", req.body);

  try {
    const { amount, currency = "eur" } = req.body;

    if (!amount) {
      console.log("Missing amount in request");
      return res.status(400).json({ error: "Amount is required" });
    }

    console.log(`Creating PaymentIntent for amount: ${amount} ${currency}`);

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: currency,
      payment_method_types: ["card"],
    });

    console.log("PaymentIntent created:", paymentIntent.id);
    res.json({ clientSecret: paymentIntent.client_secret });
  } catch (err) {
    console.error("Error creating PaymentIntent:", err);
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 5001;
const server = app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on http://0.0.0.0:${PORT}`);
});
