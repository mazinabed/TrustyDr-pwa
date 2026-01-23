import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/widget/column_builder.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientDirectory extends StatefulWidget {
  const PatientDirectory({super.key});

  @override
  _PatientDirectoryState createState() => _PatientDirectoryState();
}

class _PatientDirectoryState extends State<PatientDirectory> {
  final currentUser = FirebaseAuth.instance.currentUser;
  late final CollectionReference usersRef =
      FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: whiteColor,
        titleSpacing: 0.0,
        elevation: 1.0,
        title: Text(
          'Patient Directory',
          style: appBarTitleTextStyle,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: blackColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {},
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.where('role', isEqualTo: 'patient').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No patients found.'));
          }

          final patientList = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          return ListView(
            children: [
              Container(
                padding: EdgeInsets.all(fixPadding * 2.0),
                child: ColumnBuilder(
                  itemCount: patientList.length,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  itemBuilder: (context, index) {
                    final item = patientList[index];

                    final name = item['name'] ?? 'مريض';
                    String? imageUrl;
                    if (item.containsKey('profileImage') &&
                        item['profileImage'] != null &&
                        item['profileImage'] != '') {
                      imageUrl = item['profileImage'];
                    }

                    return Container(
                      margin: (index == 0)
                          ? const EdgeInsets.only(top: 0.0)
                          : EdgeInsets.only(top: fixPadding * 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          (imageUrl != null)
                              ? Container(
                                  width: 70.0,
                                  height: 70.0,
                                  decoration: BoxDecoration(
                                    color: whiteColor,
                                    borderRadius: BorderRadius.circular(35.0),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        blurRadius: 1.0,
                                        spreadRadius: 1.0,
                                        color: Colors.grey[300]!,
                                      ),
                                    ],
                                    image: DecorationImage(
                                        image: NetworkImage(imageUrl),
                                        fit: BoxFit.cover),
                                  ),
                                )
                              : Container(
                                  width: 70.0,
                                  height: 70.0,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(35.0),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        blurRadius: 1.0,
                                        spreadRadius: 1.0,
                                        color: Colors.grey[300]!,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    name[0],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                          widthSpace,
                          widthSpace,
                          Expanded(
                            child: Text(
                              name,
                              style: blackNormalBoldTextStyle,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
