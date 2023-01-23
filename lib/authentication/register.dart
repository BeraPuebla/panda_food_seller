import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seller_app/widgets/custom_text_field.dart';
import 'package:seller_app/widgets/error_dialog.dart';
import 'package:seller_app/widgets/loading_dialog.dart';
import 'package:firebase_storage/firebase_storage.dart' as fStorage;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  XFile? imageXFile;
  final ImagePicker _picker = ImagePicker();

  Position? position;
  List<Placemark>? placemarks;

  String sellerImageUrl = "";

  Future<void> _getImage() async{
    imageXFile = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      imageXFile;
    });
  }

  getCurrentLocation() async {
    Position newPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    position = newPosition;
    placemarks = await placemarkFromCoordinates(
      position!.latitude,
      position!.longitude,
    );
    Placemark pMark = placemarks![0];
    String completeAddress = '${pMark.subThoroughfare} ${pMark.thoroughfare}, ${pMark.subLocality} ${pMark.locality}, ${pMark.subAdministrativeArea} ${pMark.administrativeArea} ${pMark.postalCode}, ${pMark.country}';
    locationController.text = completeAddress;
  }

  Future<void> formValidation() async {
    if(imageXFile == null){
      showDialog(
        context: context,
        builder: (c){
          return const ErrorDialog(
            message: "Please select an image.",
          );
        }
      );
    }
    else{
      if(passwordController.text == confirmPasswordController.text){
        if(confirmPasswordController.text.isNotEmpty && emailController.text.isNotEmpty && nameController.text.isNotEmpty && phoneController.text.isNotEmpty && locationController.text.isNotEmpty){
          // start uploading image
          showDialog(
            context: context,
            builder: (c){
              return const LoadingDialog(
                message: "Registering Account",
              );
            }
          );
          String fileName = DateTime.now().millisecondsSinceEpoch.toString();
          fStorage.Reference reference = fStorage.FirebaseStorage.instance.ref().child("sellers").child(fileName);
          fStorage.UploadTask uploadTask = reference.putFile(File(imageXFile!.path));
          fStorage.TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
          await taskSnapshot.ref.getDownloadURL().then((url) {
            sellerImageUrl = url;
            // save info to firestore
          });
        }
        else{
        showDialog(
        context: context,
        builder: (c){
          return const ErrorDialog(
            message: "Please write the complete required info for Registration.",
          );
        }
      );  
        }
      }
      else{
        showDialog(
        context: context,
        builder: (c){
          return const ErrorDialog(
            message: "Password do not match.",
          );
        }
      );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          const SizedBox(height: 10,),
          InkWell(
            onTap: (){
              _getImage();
            },
            child: CircleAvatar(
              radius: MediaQuery.of(context).size.width * 0.20,
              backgroundColor: Colors.white,
              backgroundImage: imageXFile==null ? null : FileImage(File(imageXFile!.path)),
              child: imageXFile == null ? Icon(
                Icons.add_photo_alternate,
                size: MediaQuery.of(context).size.width * 0.20,
                color: Colors.grey,
                ) : null,
            ),
          ),
          const SizedBox(height: 10,),
          Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                  data: Icons.person,
                  controller: nameController,
                  hintText: "Name",
                  isObsecre: false,
                ),
                CustomTextField(
                  data: Icons.email,
                  controller: emailController,
                  hintText: "Email",
                  isObsecre: false,
                ),
                CustomTextField(
                  data: Icons.lock,
                  controller: passwordController,
                  hintText: "Password",
                  isObsecre: true,
                ),
                CustomTextField(
                  data: Icons.lock,
                  controller: confirmPasswordController,
                  hintText: "Confirm Password",
                  isObsecre: true,
                ),
                CustomTextField(
                  data: Icons.phone,
                  controller: phoneController,
                  hintText: "Phone",
                  isObsecre: false,
                ),
                CustomTextField(
                  data: Icons.my_location,
                  controller: locationController,
                  hintText: "Cafe/Restaurent Address",
                  isObsecre: false,
                  enabled: false,
                ),
                Container(
                  width: 400,
                  height: 40,
                  alignment: Alignment.center,
                  child: ElevatedButton.icon(
                    label: const Text(
                      "Get my Current Location",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      getCurrentLocation();
                    },
                    icon: const Icon(Icons.location_on, color: Colors.white,),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.amber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      )
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 30,),
          ElevatedButton(
            child: const Text(
              "Sign Up",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              primary: Colors.purple,
              padding: EdgeInsets.symmetric(horizontal: 80, vertical: 20)
            ),
            onPressed: (){
              formValidation();
            },
          ),
          const SizedBox(height: 30,),
      ],
      ),
    );
  }
}