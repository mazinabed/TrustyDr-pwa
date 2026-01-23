const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp(); // ✅ REQUIRED

const db = admin.firestore();


/**
 * 🔁 MOCK MODE
 * true  = fake ZainCash (current)
 * false = real ZainCash (later)
 */
const MOCK_MODE = true;

// 🔒 Server-side plans (source of truth)
const PLANS = {
  "1m": { months: 1, amount: 30000 },
  "6m": { months: 6, amount: 132000 },
  "12m": { months: 12, amount: 240000 },
};

exports.finalizeZainCashPaymentHttp = onRequest(
  {
    region: "us-central1",
    cors: true,
  },
  async (req, res) => {
    try {
      // ----------------------------------------
      // 1️⃣ CORS PREFLIGHT
      // ----------------------------------------
      if (req.method === "OPTIONS") {
        return res.status(204).send("");
      }

      // ----------------------------------------
      // 2️⃣ INPUT VALIDATION
      // ----------------------------------------
      const { orderId } = req.body || {};
      if (!orderId || typeof orderId !== "string") {
        return res.status(400).json({
          success: false,
          error: "Missing or invalid orderId",
        });
      }

      const paymentRef = db.collection("payments").doc(orderId);

      // ----------------------------------------
      // 3️⃣ TRANSACTION (IDEMPOTENT + AUTHORITATIVE)
      // ----------------------------------------
      const result = await db.runTransaction(async (tx) => {
        const paymentSnap = await tx.get(paymentRef);

        if (!paymentSnap.exists) {
          throw new Error("Payment not found");
        }

        const payment = paymentSnap.data();

        // 🔒 MOCK SAFETY GATE
        if (MOCK_MODE && payment.isMock !== true) {
          throw new Error("Finalize endpoint only accepts mock payments");
        }

        // 🔁 IDEMPOTENCY
        if (payment.status === "completed") {
          return {
            alreadyCompleted: true,
            uid: payment.uid,
            planCode: payment.planCode,
          };
        }

        if (payment.status !== "pending") {
          throw new Error(`Invalid payment status: ${payment.status}`);
        }

        // 🔒 SERVER-TRUTH PLAN VALIDATION
        const plan = PLANS[payment.planCode];
        if (!plan) {
          throw new Error("Invalid planCode on payment record");
        }

        if (
          payment.amount !== plan.amount ||
          payment.months !== plan.months
        ) {
          throw new Error("Payment record does not match server plan config");
        }

        const uid = payment.uid;
        if (!uid) {
          throw new Error("Payment record missing uid");
        }

        const doctorRef = db.collection("doctors").doc(uid);

        // 📅 Calculate next billing date (calendar-correct)
        const now = new Date();
        const nextBilling = new Date(now);
        nextBilling.setMonth(nextBilling.getMonth() + plan.months);

        // ✅ ACTIVATE SUBSCRIPTION
        tx.set(
          doctorRef,
          {
            subscriptionStatus: "active",
            subscriptionPlan: payment.planCode,
            nextBillingDate: admin.firestore.Timestamp.fromDate(nextBilling),
            isPaidUser: true,
          },
          { merge: true }
        );

        // ✅ COMPLETE PAYMENT
        tx.update(paymentRef, {
          status: "completed",
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
          completedBy: "mock-success-page",
        });

        return {
          alreadyCompleted: false,
          uid,
          planCode: payment.planCode,
        };
      });

      // ----------------------------------------
      // 4️⃣ RESPONSE
      // ----------------------------------------
      return res.status(200).json({
        success: true,
        alreadyCompleted: result.alreadyCompleted,
        planCode: result.planCode,
      });

    } catch (err) {
      console.error("Finalize payment error:", err);
      return res.status(400).json({
        success: false,
        error: err.message,
      });
    }
  }
);
const { onSchedule } = require("firebase-functions/v2/scheduler");

// Runs once per day
exports.expireSubscriptionsCron = onSchedule(
  {
    schedule: "every day 02:00", // runs once daily
    region: "us-central1",
    timeZone: "UTC",
  },
  async () => {
    const now = admin.firestore.Timestamp.now();

    const snapshot = await db
      .collection("doctors")
      .where("subscriptionStatus", "==", "active")
      .where("nextBillingDate", "<=", now)
      .get();

    if (snapshot.empty) {
      return; // nothing to expire
    }

    const batch = db.batch();

    snapshot.docs.forEach((doc) => {
      batch.update(doc.ref, {
        subscriptionStatus: "expired",
        isPaidUser: false,
        subscriptionPlan: null,
      });
    });

    await batch.commit();

    console.log(`Expired ${snapshot.size} subscriptions`);
  }
);


// const admin = require('firebase-admin');
// const cors = require('cors')({ origin: true });
// const { onRequest } = require('firebase-functions/v2/https');

// admin.initializeApp();

// exports.adminImportGoogleClinics = onRequest(
//   {
//     region: 'us-central1',
//     secrets: ['GOOGLE_PLACES_KEY'], // 🔴 REQUIRED
//   },
//   (req, res) => {
//     cors(req, res, async () => {
//       try {
//         console.log('adminImportGoogleClinics called', req.query);

//         const city = req.query.city;
//         if (!city) {
//           return res.status(400).json({ error: 'city is required' });
//         }

//         const apiKey = process.env.GOOGLE_PLACES_KEY;
//         if (!apiKey) {
//           return res.status(500).json({ error: 'Google Places API key not set' });
//         }

//         const url =
//           `https://maps.googleapis.com/maps/api/place/textsearch/json` +
//           `?query=${encodeURIComponent(city + ' hospital')}` +
//           `&key=${apiKey}`;

//         const response = await fetch(url);
//         const data = await response.json();

//         if (data.status !== 'OK' && data.status !== 'ZERO_RESULTS') {
//           console.error('Google API error:', data);
//           return res.status(500).json({
//             error: 'Google API error',
//             details: data.status,
//           });
//         }

//         const db = admin.firestore();
//         let importedCount = 0;

//         for (const place of data.results || []) {
//           if (!place.place_id || !place.geometry?.location) continue;

//           const ref = db.collection('clinic_discovery').doc(place.place_id);
//           const snap = await ref.get();
//           if (snap.exists) continue;

//           await ref.set({
//             name: place.name || '',
//             name_lower: (place.name || '').toLowerCase(),
//             address: place.formatted_address || '',
//             city,
//             latitude: place.geometry.location.lat,
//             longitude: place.geometry.location.lng,
//             specialty: 'General Practice',
//             specialty_lower: 'general practice',
//             sourceType: 'google_places',
//             sourceId: place.place_id,
//             isPlaceholder: true,
//             createdAt: admin.firestore.FieldValue.serverTimestamp(),
//           });

//           importedCount++;
//         }

//         return res.json({ success: true, count: importedCount });
//       } catch (e) {
//         console.error('IMPORT FAILED', e);
//         return res.status(500).json({ error: e.message });
//       }
//     });
//   }
// );
