import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trustydr/pages/profile/ChangePhoneNumberScreen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  User? currentUser;
  DocumentReference? userRef;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  String profileImage = 'https://via.placeholder.com/150';

  File? pickedImage;
  bool isLoading = false;

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

  Future<void> _loadUserData() async {
    if (userRef == null) return;
    final snapshot = await userRef!.get();
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      setState(() {
        nameController.text = data['name'] ?? '';
        phoneController.text = data['phoneNumber'] ?? '';
        emailController.text = data['email'] ?? '';
        profileImage =
            data['profileImage'] ?? 'https://via.placeholder.com/150';
      });
    }
  }

 Future<void> _saveProfile() async {
  if (userRef == null) return;

  if (nameController.text.trim().isEmpty ||
      emailController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('profile.fillAllFields'))),
    );
    return;
  }

  setState(() => isLoading = true);

  try {
    String imageUrl = profileImage;

    if (pickedImage != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${currentUser!.uid}.jpg');
      await storageRef.putFile(pickedImage!);
      imageUrl = await storageRef.getDownloadURL();
    }

    await userRef!.update({
      'name': nameController.text.trim(),
      'phoneNumber': phoneController.text.trim().isEmpty
          ? null
          : phoneController.text.trim(),
      'email': emailController.text.trim(),
      'profileImage': imageUrl,
    });

    if (!mounted) return;
    setState(() {
      profileImage = imageUrl;
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('profile.updatedSuccessfully'))),
    );

    Navigator.pop(context, true);
  } catch (e) {
    if (mounted) setState(() => isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr('profile.errorUpdating')}: $e')),
      );
    }
  }
}

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => pickedImage = File(picked.path));
    }
  }

  void _removePhoto() {
    setState(() {
      pickedImage = null;
      profileImage = '';
    });
  }

  void _selectOptionBottomSheet() {
    double width = MediaQuery.of(context).size.width;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Container(
          color: whiteColor,
          child: Wrap(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Container(
                      width: width,
                      padding: const EdgeInsets.all(10.0),
                      child: Text(tr('profile.chooseOption'),
                          textAlign: TextAlign.center,
                          style: blackHeadingTextStyle),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                      child:
                          _optionTile(Icons.camera_alt, tr('profile.camera')),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                      child: _optionTile(
                          Icons.photo_album, tr('profile.uploadFromGallery')),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _removePhoto();
                      },
                      child: _optionTile(
                          Icons.delete, tr('profile.removePhoto'),
                          color: Colors.red),
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

  Widget _optionTile(IconData icon, String title,
      {Color color = Colors.black}) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Icon(icon, color: color.withOpacity(0.7), size: 18),
          const SizedBox(width: 10),
          Text(title,
              style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: title == tr('profile.removePhoto')
                      ? FontWeight.bold
                      : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget getTile(String title, TextEditingController controller,
      {bool readOnly = false, VoidCallback? onTap}) {
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: fixPadding, vertical: fixPadding * 0.75),
      padding: EdgeInsets.symmetric(
          horizontal: fixPadding * 1.5, vertical: fixPadding * 1.2),
      decoration: BoxDecoration(
        color: whiteColor,
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
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey)),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.teal)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: blackColor),
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
                  InkWell(
                    onTap: _selectOptionBottomSheet,
                    child: Container(
                      width: 100.0,
                      height: 100.0,
                      margin: EdgeInsets.all(fixPadding * 4.0),
                      alignment: Alignment.bottomRight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5.0),
                        border: Border.all(width: 2.0, color: whiteColor),
                        image: DecorationImage(
                          image: pickedImage != null
                              ? FileImage(pickedImage!) as ImageProvider
                              : NetworkImage(profileImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        height: 22.0,
                        width: 22.0,
                        margin: EdgeInsets.all(fixPadding / 2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11.0),
                          border: Border.all(
                              width: 1.0, color: whiteColor.withOpacity(0.7)),
                          color: Colors.orange,
                        ),
                        child: Icon(Icons.add, color: whiteColor, size: 15.0),
                      ),
                    ),
                  ),
                  getTile(tr('profile.fullName'), nameController),
                  getTile(tr('profile.phone'), phoneController, readOnly: true,
                      onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChangePhoneNumberScreen()),
                    ).then((_) => _loadUserData());
                  }),
                  getTile(tr('profile.email'), emailController),
                  getTile(tr('profile.password'),
                      TextEditingController(text: '******'),
                      readOnly: true),
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
                          backgroundColor:
                              const Color(0xFF4A90E2), // same as before
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
                  child: CircularProgressIndicator(color: Colors.orange)),
            ),
        ],
      ),
    );
  }
}
