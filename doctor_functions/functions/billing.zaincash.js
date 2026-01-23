const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

const db = admin.firestore();

const PLANS = {
  "1m": { months: 1, amount: 30000 },
  "6m": { months: 6, amount: 132000 },
  "12m": { months: 12, amount: 240000 },
};

exports.createZainCashPaymentCallable =
  functions.https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Login required"
      );
    }

    const uid = context.auth.uid;
    const planCode = data.planCode;

    if (!PLANS[planCode]) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid plan"
      );
    }

    const plan = PLANS[planCode];
    const config = functions.config().zaincash;

    const orderId = `order_${uid}_${Date.now()}`;

    await db.collection("payments").doc(orderId).set({
      uid,
      planCode,
      amount: plan.amount,
      months: plan.months,
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const payload = {
      merchantId: config.merchant_id,
      amount: plan.amount,
      serviceType: "Doctor Subscription",
      orderId,
      redirectUrl: config.redirect_url,
      msisdn: config.msisdn,
      lang: "en",
    };

    const response = await axios.post(
      "https://api.zaincash.iq/transaction/init",
      payload,
      {
        headers: {
          Authorization: `Bearer ${config.secret}`,
        },
      }
    );

    if (!response.data?.paymentUrl) {
      throw new functions.https.HttpsError(
        "internal",
        "Failed to create payment"
      );
    }

    return {
      paymentUrl: response.data.paymentUrl,
      orderId,
    };
  });
