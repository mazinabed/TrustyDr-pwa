// import 'package:cloud_firestore/cloud_firestore.dart';

// class AppointmentBuilder {
//   AppointmentBuilder._();

//   // ✅ SINGLE SOURCE OF TRUTH
// static Map<String, dynamic> build({
//   //------------------------------------
//   // SLOT (CRITICAL)
//   //------------------------------------
//   required String scheduleId,
//   required DateTime slotStartAt,
//   required int slotDurationMinutes,

//   //------------------------------------
//   // DOCTOR
//   //------------------------------------
//   required String doctorId,
//   required String doctorName,
//   String? doctorImage,

//   required String specialtyKey,
//   required String specialtyEn,
//   required String specialtyAr,
//   required String specialtyKu,

//   //------------------------------------
//   // PATIENT
//   //------------------------------------
//   required String patientId,
//   required String patientName,

//   required bool forSelf,
//   String? relationship,
//   String? notes,
// String? phone,
// String? visitReason,
// int? priceIQD,
// String? currency,
// String? clinicAddress,
// String? centerName,

//   //------------------------------------
//   // CENTER
//   //------------------------------------
//   required String centerId,
//   required String clinicName,
//   required String provinceKey,
//   required String cityKey,

//   //------------------------------------
//   // BOOKING IDENTITY
//   //------------------------------------
//   required String bookedByUserId,
//   required String bookedByRole,
//   required String bookedByName,

//   required String source,
// })
//  {
//     final slotEndAt =
//     slotStartAt.add(Duration(minutes: slotDurationMinutes));

// final dateKey =
//     "${slotStartAt.year}-${slotStartAt.month.toString().padLeft(2, '0')}-${slotStartAt.day.toString().padLeft(2, '0')}";

// return {
//   "schemaVersion": 2,

//   //------------------------------------
//   // SLOT
//   //------------------------------------
//   "scheduleId": scheduleId,
//   "slotStartAt": Timestamp.fromDate(slotStartAt),
//   "slotEndAt": Timestamp.fromDate(slotEndAt),
//   "slotDurationMinutes": slotDurationMinutes,
//   "dateKey": dateKey,

//   //------------------------------------
//   // DOCTOR
//   //------------------------------------
//   "doctorId": doctorId,
//   "doctorName": doctorName,
//   "doctorImage": doctorImage,
//   "specialtyKey": specialtyKey,
//   "specialtyName_en": specialtyEn,
//   "specialtyName_ar": specialtyAr,
//   "specialtyName_ku": specialtyKu,

//   //------------------------------------
//   // PATIENT
//   //------------------------------------
//   "patientId": patientId,
//   "patientName": patientName,
//   "forSelf": forSelf,
//   "relationship": relationship,
//   "notes": notes,

//   //------------------------------------
//   // CENTER
//   //------------------------------------
//   "centerId": centerId,
//   "clinicName": clinicName,
//   "provinceKey": provinceKey,
//   "cityKey": cityKey,

//   //------------------------------------
//   // BOOKING
//   //------------------------------------
//   "bookedByUserId": bookedByUserId,
//   "bookedByRole": bookedByRole,
//   "bookedByName": bookedByName,
//   "source": source,
//  "phone": phone,
// "visitReason": visitReason,
// "priceIQD": priceIQD ?? 0,
// "currency": currency ?? "IQD",
// "clinicAddress": clinicAddress,
// "centerName": centerName,

//   //------------------------------------
//   // SYSTEM
//   //------------------------------------
//   "status": "pending",
//   "visitStatus": "waiting",
//   "paymentStatus": "unpaid",
//   "createdAt": FieldValue.serverTimestamp(),
//   "updatedAt": FieldValue.serverTimestamp(),
// };

//   }

// }

// import 'package:cloud_firestore/cloud_firestore.dart';

// class AppointmentBuilder {
//   AppointmentBuilder._();

//   // ✅ SINGLE SOURCE OF TRUTH
// static Future<Map<String, dynamic>> build({
//   required String scheduleId,
//   required DateTime slotStartAt,
//   required int slotDurationMinutes,
//   required String doctorId,
//   required String doctorName,
//   String? doctorImage,
//   required String specialtyKey,
//   required String specialtyEn,
//   required String specialtyAr,
//   required String specialtyKu,
//   required String patientId,
//   required String patientName,
//   required bool forSelf,
//   String? relationship,
//   String? notes,
//   String? visitReason,
//   String? provinceEn,
// String? provinceAr,
// String? provinceKu,
// String? cityEn,
// String? cityAr,
// String? cityKu,

//   required String centerId,
//   required String bookedByUserId,
//   required String bookedByRole,
//   required String bookedByName,
//   required String source,

// }) async {
//   final slotEndAt = slotStartAt.add(Duration(minutes: slotDurationMinutes));
//   final dateKey =
//       "${slotStartAt.year}-${slotStartAt.month.toString().padLeft(2, '0')}-${slotStartAt.day.toString().padLeft(2, '0')}";

//   final centerDoc = await FirebaseFirestore.instance
//       .collection('medical_centers')
//       .doc(centerId)
//       .get();

//   if (!centerDoc.exists) {
//     throw Exception("Center does not exist. centerId=$centerId");
//   }

//   final center = centerDoc.data()!;

//   final Map<String, dynamic> payload = <String, dynamic>{
//     "schemaVersion": 2,

//     // SLOT
//     "scheduleId": scheduleId,
//     "slotStartAt": Timestamp.fromDate(slotStartAt),
//     "slotEndAt": Timestamp.fromDate(slotEndAt),
//     "slotDurationMinutes": slotDurationMinutes,
//     "dateKey": dateKey,

//     // DOCTOR
//     "doctorId": doctorId,
//     "doctorName": doctorName,
//     "doctorImage": doctorImage ?? "",
// "province_en": provinceEn,
// "province_ar": provinceAr,
// "province_ku": provinceKu,

// "city_en": cityEn,
// "city_ar": cityAr,
// "city_ku": cityKu,

//     "specialtyKey": specialtyKey,
//     "specialtyName_en": specialtyEn,
//     "specialtyName_ar": specialtyAr,
//     "specialtyName_ku": specialtyKu,

//     // PATIENT
//     "patientId": patientId,
//     "patientName": patientName,
//     "forSelf": forSelf,
//     "relationship": relationship,
//     "notes": notes,
//     "visitReason": visitReason,

//     // CENTER (SNAPSHOT FROM DB)
//     "centerId": centerId,
//     "centerName": (center['name'] ?? '').toString(),

//     "clinicName": (center['clinicName'] ?? '').toString(),
//     "clinicName_en": (center['clinicName_en'] ?? '').toString(),
//     "clinicName_ar": (center['clinicName_ar'] ?? '').toString(),
//     "clinicName_ku": (center['clinicName_ku'] ?? '').toString(),

//     "clinicAddress": (center['clinicAddress'] ?? '').toString(),
//     "clinicAddress_en": (center['clinicAddress_en'] ?? '').toString(),
//     "clinicAddress_ar": (center['clinicAddress_ar'] ?? '').toString(),
//     "clinicAddress_ku": (center['clinicAddress_ku'] ?? '').toString(),

//     "provinceKey": (center['provinceKey'] ?? '').toString(),
//     "cityKey": (center['cityKey'] ?? '').toString(),
//     "phone": (center['phone'] ?? '').toString(),

//     // BOOKING
//     "bookedByUserId": bookedByUserId,
//     "bookedByRole": bookedByRole,
//     "bookedByName": bookedByName,
//     "source": source,

//     // SYSTEM
//     "status": "pending",
//     "visitStatus": "waiting",
//     "paymentStatus": "unpaid",
//     "priceIQD": 0,
//     "currency": "IQD",
//     "createdAt": FieldValue.serverTimestamp(),
//     "updatedAt": FieldValue.serverTimestamp(),
//   };

//   return payload;
// }

// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trustydr/core/utils/patient_identity_validator.dart';
import 'package:trustydr/models/patient_health_profile.dart';
import 'package:trustydr/models/patient_health_snapshot.dart';

class AppointmentBuilder {
  static final _fs = FirebaseFirestore.instance;

  /// ---------------------------------------------------------
  /// CREATE APPOINTMENT
  /// ---------------------------------------------------------
  static Future<String> create({
    // CENTER SNAPSHOT
    required String scheduleId,
    String? clinicAddress,

    // DOCTOR SNAPSHOT
    required String doctorId,
    required String doctorName,
    String? doctorImage,

    // PATIENT SNAPSHOT
    required String patientId,
    required String patientName,
    String? phone,
    String? relationship,

    // SLOT SNAPSHOT
    required DateTime slotStartAt,

    // BOOKING META
    required String source, // patient | reception | doctor
    required String bookedByUserId,
    required String bookedByName,
    required String bookedByRole,

    // OPTIONAL
    int priceIQD = 0,
    String currency = "IQD",
    String status = "pending",
    String visitStatus = "waiting",
    String? visitReason,
    String? notes,
  }) async {
    //-----------------------------------------
    // GUARD: reject invalid patient names before any Firestore work
    //-----------------------------------------
    if (!PatientIdentityValidator.isValidName(patientName)) {
      throw ArgumentError('INVALID_PATIENT_NAME');
    }

    //-----------------------------------------
    // 🔥 FETCH SCHEDULE (SOURCE OF TRUTH)
    //-----------------------------------------

    final scheduleDoc = await _fs.collection('schedules').doc(scheduleId).get();

    if (!scheduleDoc.exists) {
      throw Exception('Schedule not found.');
    }

    final schedule = scheduleDoc.data()!;

    if (schedule['slotDurationMinutes'] == null) {
      throw Exception('Schedule missing slotDurationMinutes');
    }

    final duration = schedule['slotDurationMinutes'] as int;

    final computedSlotEnd = slotStartAt.add(Duration(minutes: duration));

    if (!schedule.containsKey('province_en') ||
        !schedule.containsKey('city_en') ||
        !schedule.containsKey('clinicName')) {
      throw Exception(
        'Schedule snapshot incomplete. Cannot create appointment.',
      );
    }
    final centerId = schedule['centerId'] as String?;

    if (centerId == null || centerId.isEmpty) {
      throw Exception('Schedule missing centerId');
    }

    final centerDoc =
        await _fs.collection('medical_centers').doc(centerId).get();

    if (!centerDoc.exists) {
      throw Exception('Center not found');
    }

    final center = centerDoc.data()!;

    //-----------------------------------------
    // CENTER OPERATIONAL CHECK
    // Mirrors centerAccessProvider date logic.
    // Throws before the transaction so the UI can show a specific message.
    //-----------------------------------------
    final checkNow = DateTime.now();
    final te = center['trialEnds'];
    final se = center['subscriptionEnd'];
    final gpe = center['gracePeriodEnds'];
    final centerTrialEnds = te is Timestamp ? te.toDate() : null;
    final centerSubscriptionEnd = se is Timestamp ? se.toDate() : null;
    final centerGracePeriodEnds = gpe is Timestamp ? gpe.toDate() : null;
    final isOperational =
        (centerTrialEnds != null && checkNow.isBefore(centerTrialEnds)) ||
            (centerSubscriptionEnd != null &&
                checkNow.isBefore(centerSubscriptionEnd)) ||
            (centerGracePeriodEnds != null &&
                checkNow.isBefore(centerGracePeriodEnds));
    if (!isOperational) {
      throw Exception('CENTER_NOT_OPERATIONAL');
    }

    //-----------------------------------------
    // FETCH DOCTOR LOCALIZED NAMES
    // Reads name_en/ar/ku from public_doctors so the appointment
    // snapshot stores all three regardless of the UI locale at booking time.
    //-----------------------------------------
    final doctorDoc =
        await _fs.collection('public_doctors').doc(doctorId).get();
    final dd = doctorDoc.exists
        ? (doctorDoc.data() ?? <String, dynamic>{})
        : <String, dynamic>{};
    final rawEn = (dd['name_en'] ?? '').toString();
    final doctorNameEn = rawEn.isNotEmpty ? rawEn : doctorName;
    final rawAr = (dd['name_ar'] ?? '').toString();
    final doctorNameAr = rawAr.isNotEmpty ? rawAr : doctorNameEn;
    final rawKu = (dd['name_ku'] ?? '').toString();
    final doctorNameKu = rawKu.isNotEmpty ? rawKu : doctorNameEn;

    //-----------------------------------------
    // HEALTH SNAPSHOT (self-bookings only)
    // relationship == null → self-booking: read profile and build snapshot.
    // relationship != null → family/relative booking: always write null.
    // Profile read failure is non-blocking — appointment proceeds without snapshot.
    //-----------------------------------------
    PatientHealthSnapshot? healthSnapshot;
    if (relationship == null) {
      try {
        final healthDoc = await _fs
            .collection('patient_health_profiles')
            .doc(patientId)
            .get();
        if (healthDoc.exists && healthDoc.data() != null) {
          final profile = PatientHealthProfile.fromFirestore(healthDoc.data()!);
          healthSnapshot =
              PatientHealthSnapshot.fromProfile(profile, slotStartAt);
        }
      } catch (_) {
        // Non-blocking: snapshot stays null, booking continues.
      }
    }

    //-----------------------------------------
// 🔥 PREVENT DOUBLE BOOKING
//-----------------------------------------

    final slotId = '${scheduleId}_${slotStartAt.millisecondsSinceEpoch}';

    final docRef = _fs.collection('appointments').doc(slotId);

    try {
      await _fs.runTransaction((tx) async {
        final existing = await tx.get(docRef);

        if (existing.exists) {
          throw Exception('SLOT_ALREADY_BOOKED');
        }

        tx.set(docRef, {
          'slotId': slotId,

          /// 🔥 VERSION
          'schemaVersion': 2,

          //------------------------------------------------
          // CENTER SNAPSHOT
          //------------------------------------------------
          'centerId': schedule['centerId'],
          'centerName': schedule['clinicName'], // future architecture
          'clinicName': schedule['clinicName'], // current UI expects this
          'clinicName_en': schedule['clinicName_en'],
          'clinicName_ar': schedule['clinicName_ar'],
          'clinicName_ku': schedule['clinicName_ku'],
          'provinceKey': schedule['provinceKey'],
          'cityKey': schedule['cityKey'],

          'province_en': schedule['province_en'],
          'province_ar': schedule['province_ar'],
          'province_ku': schedule['province_ku'],

          'city_en': schedule['city_en'],
          'city_ar': schedule['city_ar'],
          'city_ku': schedule['city_ku'],
          'scheduleId': scheduleId,

          'clinicAddress': center['clinicAddress'],
          'clinicAddress_en': center['clinicAddress_en'],
          'clinicAddress_ar': center['clinicAddress_ar'],
          'clinicAddress_ku': center['clinicAddress_ku'],

          'visitType': schedule['visitType'],

          //------------------------------------------------
          // DOCTOR SNAPSHOT
          //------------------------------------------------
          'doctorId': doctorId,
          'doctorName': doctorName,
          'doctorName_en': doctorNameEn,
          'doctorName_ar': doctorNameAr,
          'doctorName_ku': doctorNameKu,
          'doctorImage': doctorImage,
          'specialtyKey': schedule['specialtyKey'],
          'specialtyName_en': schedule['specialty_en'],
          'specialtyName_ar': schedule['specialty_ar'],
          'specialtyName_ku': schedule['specialty_ku'],

          //------------------------------------------------
          // PATIENT SNAPSHOT
          //------------------------------------------------
          'patientId': patientId,
          'patientName': patientName,
          'phone': phone,
          'relationship': relationship,

          //------------------------------------------------
          // PATIENT HEALTH SNAPSHOT
          // Self-bookings: embedded at booking time (may be null if no profile).
          // Family/relative bookings: always null — account-holder health data
          // must never be presented as the relative's health data to the doctor.
          //------------------------------------------------
          'patientHealthSnapshot': healthSnapshot?.toMap(),

          //------------------------------------------------
          // SLOT SNAPSHOT
          //------------------------------------------------
          'slotStartAt': Timestamp.fromDate(slotStartAt),
          'slotEndAt': Timestamp.fromDate(computedSlotEnd),
          'slotDurationMinutes': duration,

          //------------------------------------------------
          // BOOKING META
          //------------------------------------------------
          'source': source,
          'bookedByUserId': bookedByUserId,
          'bookedByName': bookedByName,
          'bookedByRole': bookedByRole,

          //------------------------------------------------
          // FINANCIAL
          //------------------------------------------------
          'priceIQD': priceIQD,
          'currency': currency,
          'paymentStatus': 'unpaid',

          //------------------------------------------------
          // STATUS
          //------------------------------------------------
          'status': status,
          'visitStatus': visitStatus,

          //------------------------------------------------
          // NOTES
          //------------------------------------------------
          'visitReason': visitReason,
          'notes': notes,

          //------------------------------------------------
          // TIME
          //------------------------------------------------
          'appointmentAt': Timestamp.fromDate(slotStartAt),
          'dateKey':
              "${slotStartAt.year}-${slotStartAt.month.toString().padLeft(2, '0')}-${slotStartAt.day.toString().padLeft(2, '0')}",
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }); // ✅ CLOSE TRANSACTION
    } catch (_) {
      final check = await docRef.get();
      if (check.exists) throw Exception('SLOT_ALREADY_BOOKED');
      rethrow;
    }

    return slotId; // ✅ RETURN AFTER TRANSACTION
  }
}
