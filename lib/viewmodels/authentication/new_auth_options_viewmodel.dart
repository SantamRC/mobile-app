import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile_app/enums/auth_type.dart';
import 'package:mobile_app/enums/view_state.dart';
import 'package:mobile_app/locator.dart';
import 'package:mobile_app/models/user.dart' as app_user;
import 'package:mobile_app/services/local_storage_service.dart';
import 'package:mobile_app/viewmodels/base_viewmodel.dart';

class NewAuthOptionsViewModel extends BaseModel {
  final LocalStorageService _storage = locator<LocalStorageService>();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final String FIREBASE_GOOGLE_AUTH = 'firebase_google_auth';

  Future<void> signInWithGoogle() async {
    try {
      setStateFor(FIREBASE_GOOGLE_AUTH, ViewState.Busy);

      // Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        setStateFor(FIREBASE_GOOGLE_AUTH, ViewState.Idle);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;

        // Create a User object from Firebase data
        final user = app_user.User(
          data: app_user.Data(
            id: firebaseUser.uid,
            type: 'users',
            attributes: app_user.UserAttributes(
              name: firebaseUser.displayName ?? 'User',
              email: firebaseUser.email,
              subscribed: false,
              admin: false,
              profilePicture: firebaseUser.photoURL,
            ),
          ),
        );

        // Store user in local storage
        _storage.currentUser = user;
        _storage.isLoggedIn = true;
        _storage.authType = AuthType.GOOGLE;

        setStateFor(FIREBASE_GOOGLE_AUTH, ViewState.Success);
      } else {
        setErrorMessageFor(
          FIREBASE_GOOGLE_AUTH,
          'Failed to retrieve user information',
        );
        setStateFor(FIREBASE_GOOGLE_AUTH, ViewState.Error);
      }
    } catch (e) {
      setErrorMessageFor(FIREBASE_GOOGLE_AUTH, e.toString());
      setStateFor(FIREBASE_GOOGLE_AUTH, ViewState.Error);
    }
  }

  String? getUserName() {
    return _storage.currentUser?.data.attributes.name;
  }
}