import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Patient-side diagnostic booking service.
///
/// Mirrors [createLabScheduledOrder] in the doctor portal:
///   - writes [clinical_requests] with source='scheduled', partnerStatus='pendingApproval'
///   - always uses the slot-lock transaction path (no fallback)
///   - [createdByRole] = 'patient'
///   - [patientId] must equal the signed-in user's UID
///
/// partnerStatus begins as 'pendingApproval' — lab reception must approve
/// before it transitions to 'scheduled'.
class LabRequestService {
  LabRequestService._();

  static final _fs = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<String> createScheduledRequest({
    required String labId,
    required String centerId,
    required String slotId,
    required String scheduleId,
    required DateTime slotStartAt,
    // serviceGroup: the provider's service group key, e.g. 'laboratory' or
    // 'imaging'. Stored as serviceCategory in the clinical_request so the
    // doctor portal can translate it via 'clinical_requests.category_<key>'.
    required String serviceGroup,
    // specialtyId: the specialties collection doc ID selected by the patient.
    // Stored in subTypeItems so doctor portal and patient results page can
    // display the localized service name rather than the raw doc ID.
    required String specialtyId,
    required String serviceNameEn,
    required String serviceNameAr,
    required String serviceNameKu,
    required String patientId,
    required String patientName,
    required String patientIdentityKey,
    String patientPhone = '',
    String instructions = '',
    // Provider snapshot fields — written once at booking time so
    // PatientAppointmentItem can display without a runtime join.
    String providerNameEn = '',
    String providerNameAr = '',
    String providerNameKu = '',
    String providerAddress = '',
    String providerImage = '',
    String providerPhone = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('NOT_AUTHENTICATED');

    final baghdadLocal = slotStartAt.toUtc().add(const Duration(hours: 3));
    final dateKey =
        '${baghdadLocal.year}-${baghdadLocal.month.toString().padLeft(2, '0')}-${baghdadLocal.day.toString().padLeft(2, '0')}';

    final slotLockRef = _fs.collection('slot_locks').doc(slotId);
    final requestRef = _fs.collection('clinical_requests').doc();

    // Build the snapshotted subTypeItems entry so every reader (doctor portal
    // card, patient results page) can resolve the localized service name
    // without a runtime join back to the specialties collection.
    final subTypeItems = [
      {
        'id': specialtyId,
        'isCustom': true,
        'nameEn': serviceNameEn,
        'nameAr': serviceNameAr,
        'nameKu': serviceNameKu,
      }
    ];

    try {
      await _fs.runTransaction((tx) async {
        final existingLock = await tx.get(slotLockRef);
        if (existingLock.exists) {
          throw Exception('SLOT_ALREADY_BOOKED');
        }

        tx.set(slotLockRef, {
          'appointmentId': requestRef.id,
          'centerId': centerId,
          'dateKey': dateKey,
          'lockedBy': user.uid,
          'lockedAt': FieldValue.serverTimestamp(),
        });

        tx.set(requestRef, {
          'centerId': centerId,
          'appointmentId': '',
          'patientId': patientId,
          'patientName': patientName,
          'patientIdentityKey': patientIdentityKey,
          'patientPhone': patientPhone,
          'doctorId': '',
          'doctorName': '',
          'dateKey': dateKey,
          // serviceCategory uses the provider's serviceGroup key so the doctor
          // portal can render 'clinical_requests.category_laboratory' etc.
          'serviceCategory': serviceGroup,
          'subType': serviceGroup,
          'subTypeItems': subTypeItems,
          'assignedRoles': <String>[],
          'status': 'pending',
          'requestDestination': 'partner',
          'partnerProviderId': labId,
          // pendingApproval: lab reception must approve before it becomes scheduled.
          'partnerStatus': 'pendingApproval',
          'source': 'scheduled',
          'slotId': slotId,
          'scheduleId': scheduleId,
          'slotStartAt': Timestamp.fromDate(slotStartAt),
          'instructions': instructions,
          'createdByRole': 'patient',
          // Provider snapshot — avoids runtime join in PatientAppointmentItem.
          'providerName_en': providerNameEn,
          'providerName_ar': providerNameAr,
          'providerName_ku': providerNameKu,
          'providerAddress': providerAddress,
          'providerImage': providerImage,
          'providerPhone': providerPhone,
          'providerKind': serviceGroup,
          'schemaVersion': 1,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (e.toString().contains('SLOT_ALREADY_BOOKED')) rethrow;
      final check = await slotLockRef.get();
      if (check.exists) throw Exception('SLOT_ALREADY_BOOKED');
      rethrow;
    }

    return requestRef.id;
  }
}
