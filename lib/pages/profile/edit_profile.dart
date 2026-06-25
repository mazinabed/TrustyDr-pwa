// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:trustydr/pages/profile/ChangePhoneNumberScreen.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:trustydr/constant/constant.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';

// class EditProfile extends StatefulWidget {
//   const EditProfile({super.key});

//   @override
//   _EditProfileState createState() => _EditProfileState();
// }

// class _EditProfileState extends State<EditProfile> {
//   User? currentUser;
//   DocumentReference? userRef;

//   final nameController = TextEditingController();
//   final phoneController = TextEditingController();
//   final emailController = TextEditingController();

//   String profileImage = 'https://via.placeholder.com/150';

//   File? pickedImage;
//   bool isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser != null) {
//       userRef =
//           FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
//       _loadUserData();
//     }
//   }

//   Future<void> _loadUserData() async {
//     if (userRef == null) return;
//     final snapshot = await userRef!.get();
//     if (snapshot.exists) {
//       final data = snapshot.data() as Map<String, dynamic>;
//       setState(() {
//         nameController.text = data['name'] ?? '';
//         phoneController.text = data['phoneNumber'] ?? '';
//         emailController.text = data['email'] ?? '';
//         profileImage =
//             data['profileImage'] ?? 'https://via.placeholder.com/150';
//       });
//     }
//   }

//  Future<void> _saveProfile() async {
//   if (userRef == null) return;

//   if (nameController.text.trim().isEmpty ||
//       emailController.text.trim().isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(tr('profile.fillAllFields'))),
//     );
//     return;
//   }

//   setState(() => isLoading = true);

//   try {
//     String imageUrl = profileImage;

//     if (pickedImage != null) {
//       final storageRef = FirebaseStorage.instance
//           .ref()
//           .child('profile_images/${currentUser!.uid}.jpg');
//       await storageRef.putFile(pickedImage!);
//       imageUrl = await storageRef.getDownloadURL();
//     }

//     await userRef!.update({
//       'name': nameController.text.trim(),
//       'phoneNumber': phoneController.text.trim().isEmpty
//           ? null
//           : phoneController.text.trim(),
//       'email': emailController.text.trim(),
//       'profileImage': imageUrl,
//     });

//     if (!mounted) return;
//     setState(() {
//       profileImage = imageUrl;
//       isLoading = false;
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(tr('profile.updatedSuccessfully'))),
//     );

//     Navigator.pop(context, true);
//   } catch (e) {
//     if (mounted) setState(() => isLoading = false);
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('${tr('profile.errorUpdating')}: $e')),
//       );
//     }
//   }
// }

//   Future<void> _pickImage(ImageSource source) async {
//     final picker = ImagePicker();
//     final picked = await picker.pickImage(source: source, imageQuality: 80);
//     if (picked != null) {
//       setState(() => pickedImage = File(picked.path));
//     }
//   }

//   void _removePhoto() {
//     setState(() {
//       pickedImage = null;
//       profileImage = '';
//     });
//   }

//   void _selectOptionBottomSheet() {
//     double width = MediaQuery.of(context).size.width;
//     showModalBottomSheet(
//       context: context,
//       builder: (BuildContext bc) {
//         return Container(
//           color: Colors.white,
//           child: Wrap(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Column(
//                   children: [
//                     Container(
//                       width: width,
//                       padding: const EdgeInsets.all(10.0),
//                       child: Text(tr('profile.chooseOption'),
//                           textAlign: TextAlign.center,
//                           style: blackHeadingTextStyle),
//                     ),
//                     InkWell(
//                       onTap: () {
//                         Navigator.pop(context);
//                         _pickImage(ImageSource.camera);
//                       },
//                       child:
//                           _optionTile(Icons.camera_alt, tr('profile.camera')),
//                     ),
//                     InkWell(
//                       onTap: () {
//                         Navigator.pop(context);
//                         _pickImage(ImageSource.gallery);
//                       },
//                       child: _optionTile(
//                           Icons.photo_album, tr('profile.uploadFromGallery')),
//                     ),
//                     InkWell(
//                       onTap: () {
//                         Navigator.pop(context);
//                         _removePhoto();
//                       },
//                       child: _optionTile(
//                           Icons.delete, tr('profile.removePhoto'),
//                           color: Colors.red),
//                     ),
//                   ],
//                 ),
//               )
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _optionTile(IconData icon, String title,
//       {Color color = Colors.black}) {
//     return Container(
//       padding: const EdgeInsets.all(10.0),
//       child: Row(
//         children: [
//           Icon(icon, color: color.withOpacity(0.7), size: 18),
//           const SizedBox(width: 10),
//           Text(title,
//               style: TextStyle(
//                   color: color,
//                   fontSize: 15,
//                   fontWeight: title == tr('profile.removePhoto')
//                       ? FontWeight.bold
//                       : FontWeight.normal)),
//         ],
//       ),
//     );
//   }

//   Widget getTile(String title, TextEditingController controller,
//       {bool readOnly = false, VoidCallback? onTap}) {
//     return Container(
//       margin: EdgeInsets.symmetric(
//           horizontal: fixPadding, vertical: fixPadding * 0.75),
//       padding: EdgeInsets.symmetric(
//           horizontal: fixPadding * 1.5, vertical: fixPadding * 1.2),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: [
//           BoxShadow(
//             blurRadius: 2,
//             spreadRadius: 1,
//             color: Colors.grey[200]!,
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title, style: greyNormalTextStyle),
//           const SizedBox(height: 6),
//           TextField(
//             controller: controller,
//             readOnly: readOnly,
//             onTap: readOnly ? onTap : null,
//             decoration: const InputDecoration(
//               isDense: true,
//               border: OutlineInputBorder(),
//               enabledBorder: OutlineInputBorder(
//                   borderSide: BorderSide(color: Colors.grey)),
//               focusedBorder: OutlineInputBorder(
//                   borderSide: BorderSide(color: PatientAppColors.brandTeal)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: PatientAppColors.surface,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0.0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Stack(
//         children: [
//           ListView(
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   InkWell(
//                     onTap: _selectOptionBottomSheet,
//                     child: Container(
//                       width: 100.0,
//                       height: 100.0,
//                       margin: EdgeInsets.all(fixPadding * 4.0),
//                       alignment: Alignment.bottomRight,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(5.0),
//                         border: Border.all(width: 2.0, color: Colors.white),
//                         image: DecorationImage(
//                           image: pickedImage != null
//                               ? FileImage(pickedImage!) as ImageProvider
//                               : NetworkImage(profileImage),
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                       child: Container(
//                         height: 22.0,
//                         width: 22.0,
//                         margin: EdgeInsets.all(fixPadding / 2),
//                         alignment: Alignment.center,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(11.0),
//                           border: Border.all(
//                               width: 1.0, color: Colors.white.withOpacity(0.7)),
//                           color: Colors.orange,
//                         ),
//                         child: Icon(Icons.add, color: Colors.white, size: 15.0),
//                       ),
//                     ),
//                   ),
//                   getTile(tr('profile.fullName'), nameController),
//                   getTile(tr('profile.phone'), phoneController, readOnly: true,
//                       onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (_) => const ChangePhoneNumberScreen()),
//                     ).then((_) => _loadUserData());
//                   }),
//                   getTile(tr('profile.email'), emailController),
//                   getTile(tr('profile.password'),
//                       TextEditingController(text: '******'),
//                       readOnly: true),
//                   const SizedBox(height: 20),
//                   Padding(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: fixPadding * 2,
//                       vertical: fixPadding * 2,
//                     ),
//                     child: SizedBox(
//                       width: double.infinity,
//                       height: 48,
//                       child: ElevatedButton(
//                         onPressed: isLoading ? null : _saveProfile,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor:
//                               const Color(0xFF4A90E2), // same as before
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                         child: isLoading
//                             ? const SizedBox(
//                                 height: 20,
//                                 width: 20,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                   color: Colors.white,
//                                 ),
//                               )
//                             : Text(
//                                 tr('profile.save'),
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           if (isLoading)
//             Container(
//               color: Colors.black.withOpacity(0.3),
//               child: const Center(
//                   child: CircularProgressIndicator(color: Colors.orange)),
//             ),
//         ],
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trustydr/pages/profile/account_connections_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:io'
    show File; // ✅ allowed ONLY because we will guard it with !kIsWeb

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  User? currentUser;
  DocumentReference? userRef;

  final nameController = TextEditingController();

  String profileImage = '';

  XFile? pickedImage;
  Uint8List? _pickedWebBytes;
  bool isLoading = false;

  // ✅ PATCH architecture state (initial snapshot for change-detection)
  String _initialName = '';
  String _initialProfileImage = '';
  bool _loaded = false;

  // ✅ Explicit intent flag so "empty string" never accidentally wipes data
  bool _photoRemoveRequested = false;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      userRef =
          FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
      _loadUserData();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (userRef == null) return;

    final snapshot = await userRef!.get();
    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;

    final name = (data['name'] ?? '').toString();
    final rawImg = (data['profileImage'] ?? '').toString().trim();
    final img =
        (rawImg.startsWith('http') && !rawImg.contains('placeholder.com'))
            ? rawImg
            : '';

    if (!mounted) return;

    setState(() {
      nameController.text = name;
      profileImage = img;

      // ✅ snapshot for PATCH detection
      _initialName = name;
      _initialProfileImage = img;

      // reset intent flags
      pickedImage = null;
      _photoRemoveRequested = false;

      _loaded = true;
    });
  }

  /// ✅ Production-safe: PATCH-only update.
  /// - updates ONLY fields changed (name, profileImage)
  /// - does NOT overwrite with empty values
  /// - Photo removal: deletes Firestore field + Storage file
  Future<void> _saveProfile() async {
    if (userRef == null || currentUser == null) return;
    if (!_loaded) return;

    setState(() => isLoading = true);

    try {
      final updates = <String, dynamic>{};

      final newName = nameController.text.trim();

      // ✅ Name: update only if non-empty and changed.
      if (newName.isNotEmpty && newName != _initialName) {
        updates['name'] = newName;
      }

      // ✅ Image handling (upload OR explicit clear)
      String? uploadedUrl;

      if (pickedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images/${currentUser!.uid}.jpg');

        if (kIsWeb) {
          final Uint8List bytes =
              _pickedWebBytes ?? await pickedImage!.readAsBytes();
          await storageRef.putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
        } else {
          await storageRef.putFile(File(pickedImage!.path));
        }

        uploadedUrl = await storageRef.getDownloadURL();

        if (uploadedUrl != _initialProfileImage) {
          updates['profileImage'] = uploadedUrl;
        }
      } else if (_photoRemoveRequested) {
        // ✅ Explicit removal intent: delete Firestore field + delete Storage file (2A)
        updates['profileImage'] = FieldValue.delete();

        // Best-effort delete. If file doesn't exist, ignore.
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_images/${currentUser!.uid}.jpg');
          await storageRef.delete();
        } catch (_) {
          // ignore: missing file / no permission / already deleted
        }
      }

      // ✅ Audit field (only when there is a real change)
      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
      }

      // ✅ No changes => no write
      if (updates.isEmpty) {
        if (!mounted) return;
        setState(() => isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('profile.noChanges'))),
        );
        return;
      }

      await userRef!.update(updates);

      if (!mounted) return;

      // ✅ Update local state + initial snapshot (prevents repeated writes)
      setState(() {
        if (updates.containsKey('name')) _initialName = newName;

        if (updates.containsKey('profileImage')) {
          if (uploadedUrl != null) {
            profileImage = uploadedUrl;
            _initialProfileImage = uploadedUrl;
          } else {
            // deleted
            profileImage = '';
            _initialProfileImage = '';
          }
        }

        pickedImage = null;
        _pickedWebBytes = null;
        _photoRemoveRequested = false;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('profile.updatedSuccessfully'))),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr('profile.errorUpdating')}: $e')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        pickedImage = picked;
        _pickedWebBytes = bytes;
        _photoRemoveRequested = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        pickedImage = picked;
        _pickedWebBytes = null;
        _photoRemoveRequested = false;
      });
    }
  }

  /// ✅ Explicit removal intent (handled in _saveProfile as FieldValue.delete + Storage delete)
  void _removePhoto() {
    setState(() {
      pickedImage = null;
      _pickedWebBytes = null;
      profileImage = '';
      _photoRemoveRequested = true;
    });
  }

  void _selectOptionBottomSheet() {
    double width = MediaQuery.of(context).size.width;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Container(
          color: Colors.white,
          child: Wrap(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Container(
                      width: width,
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        tr('profile.chooseOption'),
                        textAlign: TextAlign.center,
                        style: blackHeadingTextStyle,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                      child: _optionTile(
                        Icons.camera_alt,
                        tr('profile.camera'),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                      child: _optionTile(
                        Icons.photo_album,
                        tr('profile.uploadFromGallery'),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _removePhoto();
                      },
                      child: _optionTile(
                        Icons.delete,
                        tr('profile.removePhoto'),
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _optionTile(
    IconData icon,
    String title, {
    Color color = Colors.black,
  }) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Icon(icon, color: color.withOpacity(0.7), size: 18),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: title == tr('profile.removePhoto')
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountConnectionsCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: fixPadding,
        vertical: fixPadding * 0.75,
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AccountConnectionsScreen(),
          ),
        ),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: fixPadding * 1.5,
            vertical: fixPadding * 1.2,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                blurRadius: 2,
                spreadRadius: 1,
                color: Colors.grey[200]!,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: PatientAppColors.brandIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.link,
                  color: PatientAppColors.brandIndigo,
                  size: 20,
                ),
              ),
              SizedBox(width: fixPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('account_connections.title'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr('account_connections.subtitle'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getTile(
    String title,
    TextEditingController controller, {
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    List<String>? autofillHints,
    String? helperText,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: fixPadding,
        vertical: fixPadding * 0.75,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: fixPadding * 1.5,
        vertical: fixPadding * 1.2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            blurRadius: 2,
            spreadRadius: 1,
            color: Colors.grey[200]!,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: greyNormalTextStyle),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: readOnly ? onTap : null,
            keyboardType: keyboardType,
            autofillHints: autofillHints,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey)),
              focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: PatientAppColors.brandTeal)),
              helperText: helperText,
              helperMaxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasRealPhoto =>
      pickedImage != null ||
      (profileImage.isNotEmpty && profileImage.startsWith('http'));

  Widget _buildAvatar() {
    if (_hasRealPhoto) {
      return Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(width: 3, color: Colors.white),
          image: DecorationImage(
            image: _resolveProfileImageProvider(),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: 104,
      height: 104,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: PatientAppColors.brandGradient,
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 52),
    );
  }

  ImageProvider _resolveProfileImageProvider() {
    if (pickedImage != null) {
      if (kIsWeb && _pickedWebBytes != null) {
        return MemoryImage(_pickedWebBytes!);
      } else if (!kIsWeb) {
        return FileImage(File(pickedImage!.path));
      }
    }

    final url = profileImage.trim();
    if (url.isNotEmpty && url.startsWith('http')) {
      return NetworkImage(url);
    }
    return const AssetImage('assets/user/placeholder_user.png');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PatientAppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: PatientAppColors.brandIndigo),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(fixPadding * 3.0),
                    child: InkWell(
                      onTap: _selectOptionBottomSheet,
                      borderRadius: BorderRadius.circular(52),
                      child: Stack(
                        children: [
                          _buildAvatar(),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: PatientAppColors.brandTeal,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  getTile(tr('profile.fullName'), nameController),
                  _accountConnectionsCard(context),
                  const SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: fixPadding * 2,
                      vertical: fixPadding * 2,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PatientAppColors.brandBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                tr('profile.save'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              ),
            ),
        ],
      ),
    );
  }
}
