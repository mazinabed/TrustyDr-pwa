/**
 * FULL DEEP NORMALIZATION SCRIPT (Option C)
 * -----------------------------------------
 * Safe to run. Does not delete data.
 * Moves invalid entries to backup collections.
 */

const admin = require("firebase-admin");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// YOUR OFFICIAL PROVINCE LIST (from cities collection)
const OFFICIAL_PROVINCES = {
  basra: "Basra City",
  baghdad: "Baghdad",
  karbala: "Karbala City",
  najaf: "Najaf City",
  sulaymaniyah: "Sulaymaniyah City",
  erbil: "Erbil City",
  kirkuk: "Kirkuk City",
  wasit: "Hay Wasit"
  // add more if needed...
};

function normalizeText(s) {
  if (!s) return "";
  return s
    .replace(/\s+/g, " ")
    .replace(/[^\w\s]/g, "")
    .trim();
}

// Extracts key: "Basra City basra" -> {key:"basra", name:"Basra City"}
function extractProvinceName(value) {
  if (!value) return { key: null, name: null };

  const parts = value.split(" ");
  const last = parts[parts.length - 1].toLowerCase();

  if (OFFICIAL_PROVINCES[last]) {
    return {
      key: last,
      name: OFFICIAL_PROVINCES[last],
    };
  }

  const cleaned = value.replace(/baghdad|basra|najaf|karbala|city/gi, "").trim();
  const normalized = normalizeText(cleaned);

  return { key: null, name: normalized || value };
}

async function normalizeDoctors() {
  console.log("⏳ Loading doctors...");
  const snap = await db.collection("doctors").get();

  console.log(`Found ${snap.size} doctors.`);
  let countUpdated = 0;
  let countInvalid = 0;

  for (const doc of snap.docs) {
    const d = doc.data();

    // BASIC CLEAN EXTRACTION
    const { key: extractedKey, name: extractedProvName } = extractProvinceName(
      d.province
    );

    let province_key = d.province_key || extractedKey;
    let province = extractedProvName;

    // If province still invalid → move to invalid collection
    const keyIsValid = province_key && OFFICIAL_PROVINCES[province_key];

    if (!keyIsValid) {
      console.log("⚠ INVALID PROVINCE → moving", d.name);
      await db.collection("doctors_invalid").doc(doc.id).set(d);
      countInvalid++;
      continue;
    }

    // Normalize city from provinces list
    let city = d.city;
    let city_en = d.city_en;

    const officialCityList = OFFICIAL_PROVINCES[province_key];
    if (!city || !city_en) {
      city = officialCityList;
      city_en = officialCityList;
    }

    // Build update object
    const updates = {
      province_key,
      province: OFFICIAL_PROVINCES[province_key],
      city,
      city_en,
      name_lower: d.name?.toLowerCase() || "",
      specialty_lower: (d.specialty || "").toLowerCase(),
      sourceType: d.sourceType || "google_places",
    };

    await doc.ref.update(updates);
    countUpdated++;
  }

  console.log("-------------------------------------------------------");
  console.log("✔ NORMALIZATION COMPLETE");
  console.log(`Updated valid doctors: ${countUpdated}`);
  console.log(`Moved invalid doctors: ${countInvalid}`);
  console.log("-------------------------------------------------------");
}

normalizeDoctors()
  .then(() => process.exit())
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
