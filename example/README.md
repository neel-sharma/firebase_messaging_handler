example
An example application for the implementation of Notification Utility using Firebase Messaging Handler Plugin.

Getting Started
To set up and run the example application, follow these steps:

1. Create a Firebase Project

   Go to the Firebase Console.
   Click on "Add project" and follow the instructions to create a new Firebase project.
   Once the project is created, navigate to the project dashboard.

2. Install the Firebase CLI tools if you haven't already:

   npm install -g firebase-tools

3. Log in to your Firebase account using the Firebase CLI:
 
   firebase login

4. Activate the FlutterFire CLI to configure Firebase for your Flutter project:

   dart pub global activate flutterfire_cli

5. Configure Firebase for Your Flutter Project. Navigate to the root directory of your example application and run the following command to configure Firebase:

   flutterfire configure

   This command will guide you through selecting your Firebase project and configuring the necessary files. Follow these steps:

   Select your Firebase project from the list.
   Select the platforms you are developing for (iOS, Android, etc.).
   The CLI will automatically generate and add the necessary Firebase configuration files (google-services.json for Android and GoogleService-Info.plist for iOS) to your Flutter project.

6. Run the Example Application
 