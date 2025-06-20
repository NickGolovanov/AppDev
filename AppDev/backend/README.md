# AppDev Stripe Backend

A minimal Node.js backend for Stripe Payment Intents.

## Setup

1. Install dependencies:
   ```
   npm install
   ```
2. Copy `.env` and add your Stripe secret key:
   ```
   STRIPE_SECRET_KEY=sk_test_your_secret_key_here
   PORT=5001
   ```
3. Start the server:
   ```
   npm start
   ```

## Endpoint

POST `/createPaymentIntent`

- **Body:** `{ amount, currency, eventId, userId }`
- **Returns:** `{ clientSecret }` on success

## Notes

- If testing on a real device, use your computer's local IP address in your iOS app instead of `localhost`.
- Never expose your Stripe secret key in frontend code.
