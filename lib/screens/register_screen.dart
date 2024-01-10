import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:phoneauth_firebase/provider/auth_provider.dart';
import 'package:phoneauth_firebase/screens/welcome_screen.dart';
import 'package:provider/provider.dart';

import '../widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController phoneController = TextEditingController();

// default country setup in country picker
  Country selectedCountry = Country(
    phoneCode: "91", 
    countryCode: "IN", 
    e164Sc: 0, 
    geographic: true, 
    level: 1, 
    name: "India", 
    example: "India", 
    displayName: "India", 
    displayNameNoCountryCode: "IN", 
    e164Key: ""
    );

  @override
  Widget build(BuildContext context) {

    phoneController.selection = TextSelection.fromPosition(
      TextPosition(offset: phoneController.text.length)
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 35),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.purple.shade50
                  ),
                  child: Image.asset("assets/image2.png"),
                ),
                const SizedBox(height: 20,),
                const Text(
                  "Register",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                "Add your phone number. We'll send you a verification code",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,color: Colors.black38,),
                textAlign: TextAlign.center,
              ),
               
              const SizedBox(height: 20,),
              //Custom button
              TextFormField(
                cursorColor: Colors.purple,
                controller: phoneController,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                maxLength: 10,
                onChanged: (value){
                 setState(() {
                    phoneController.text = value;
                 });
                },
                decoration: InputDecoration(
                  hintText: "Enter phone number",
                  hintStyle: TextStyle(fontWeight: FontWeight.w500,fontSize: 15,color: Colors.grey.shade600),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.black12)
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.black12)),
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () {
                          showCountryPicker(
                            context: context, 
                            countryListTheme: const CountryListThemeData(
                              bottomSheetHeight: 550
                            ),
                            onSelect: (value){
                              setState(() {
                                selectedCountry = value;
                              });
                            }
                            );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            "${selectedCountry.flagEmoji} + ${selectedCountry.phoneCode}",
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ),
                    ),
                    suffixIcon: phoneController.text.length > 9 ? Container(
                      height: 30,
                      width: 30,
                      margin: const EdgeInsets.all(10.0),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                      child: const Icon(
                        Icons.done,
                        color: Colors.white,
                        size: 20,
                      ),
                    ) : null,
                ),
              
              ),
               const SizedBox(
              height: 20,
            ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: CustoomButton(
                  text: "Login", 
                  onPressed: (){
                    sendPhoneNumber();
                  }),
              )
              ],
              
             
          ),
        ),
      )
    );
  }


  void sendPhoneNumber(){
    //+911234567890  --> for firebase testing
    final ap = Provider.of<AuthProvider>(context, listen: false);
    String phoneNumber = phoneController.text.trim();
    ap.signInWithPhone(context, "+${selectedCountry.phoneCode}$phoneNumber");


  }
}