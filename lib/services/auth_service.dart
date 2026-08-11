import 'package:firebase_auth/firebase_auth.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';
import 'firestore_service.dart';

/// Wraps all Firebase Authentication logic: email/password login & signup,
/// forgot password, and Google Sign-In. Every method throws a
/// [FirebaseAuthException] on failure — the UI layer (screens) is
/// responsible for catching it and showing a friendly message.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  
  // Removing clientId allows Android to correctly pick it up from google-services.json
  // which resolves many Google Sign-In misconfiguration issues.
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '972583496173-7hudr6all031ef136thjhqf42c6e7lj6.apps.googleusercontent.com' : null,
  );

  /// Stream of auth state changes — use this to decide whether to show
  /// the login screen or the home screen (see main.dart AuthGate).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ---------------- EMAIL / PASSWORD ----------------

  Future<UserCredential> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Set the display name on the Firebase Auth user
    await credential.user?.updateDisplayName(name);

    // Create the matching Firestore profile document
    final user = UserModel(
      uid: credential.user!.uid,
      name: name,
      email: email.trim(),
      photoUrl: credential.user?.photoURL,
    );
    await _firestoreService.createUserProfile(user);

    return credential;
  }

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ---------------- GOOGLE SIGN-IN ----------------

  Future<UserCredential?> signInWithGoogle() async {
    UserCredential userCredential;

    if (kIsWeb) {
      // On Web, use Firebase Auth's popup flow directly.
      // This routes through Firebase's authorized OAuth handler domain,
      // avoiding Google 400 origin_mismatch errors on local development ports.
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      userCredential = await _auth.signInWithPopup(googleProvider);
    } else {
      // On Mobile (Android / iOS), use google_sign_in package native flow.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User cancelled the picker
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      userCredential = await _auth.signInWithCredential(credential);
    }

    // If this is the user's first time signing in with Google,
    // create their Firestore profile document too.
    final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
    if (isNewUser && userCredential.user != null) {
      final user = UserModel(
        uid: userCredential.user!.uid,
        name: userCredential.user!.displayName ?? 'GymMate User',
        email: userCredential.user!.email ?? '',
        photoUrl: userCredential.user!.photoURL,
      );
      await _firestoreService.createUserProfile(user);
    }

    return userCredential;
  }

  // ---------------- PHONE AUTHENTICATION ----------------

  ConfirmationResult? _webConfirmationResult;

  /// Sends OTP on Web using Firebase Web Recaptcha / Phone Auth
  Future<ConfirmationResult> signInWithPhoneWeb(String phoneNumber) async {
    final verifier = RecaptchaVerifier(
      auth: FirebaseAuthPlatform.instance,
      container: 'recaptcha-container',
      size: RecaptchaVerifierSize.normal,
    );
    _webConfirmationResult = await _auth.signInWithPhoneNumber(
      phoneNumber.trim(),
      verifier,
    );
    return _webConfirmationResult!;
  }

  /// Verifies OTP code on Web
  Future<UserCredential> confirmWebOtp(String code) async {
    if (_webConfirmationResult == null) {
      throw FirebaseAuthException(
        code: 'no-pending-otp',
        message: 'No pending OTP verification found. Please request a new code.',
      );
    }
    final userCredential = await _webConfirmationResult!.confirm(code);
    final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
    if (isNewUser && userCredential.user != null) {
      final user = UserModel(
        uid: userCredential.user!.uid,
        name: 'GymMate User',
        email: '',
        photoUrl: userCredential.user?.photoURL,
      );
      await _firestoreService.createUserProfile(user);
    }
    return userCredential;
  }

  /// Sends OTP on Mobile (Android / iOS)
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserCredential> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    final userCredential = await _auth.signInWithCredential(credential);

    final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
    if (isNewUser && userCredential.user != null) {
      final user = UserModel(
        uid: userCredential.user!.uid,
        name: 'GymMate User',
        email: '',
        photoUrl: userCredential.user?.photoURL,
      );
      await _firestoreService.createUserProfile(user);
    }

    return userCredential;
  }

  // ---------------- SIGN OUT ----------------

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore errors if Google Sign In isn't initialized or used
    }
    await _auth.signOut();
  }

  /// Converts common FirebaseAuthException codes into readable messages
  /// so screens can show something better than a raw error code.
  static String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-phone-number':
        return 'The provided phone number is invalid. Format: +[CountryCode][Number] (e.g. +91 9949881730).';
      case 'invalid-verification-code':
        return 'The OTP entered is incorrect.';
      case 'too-many-requests':
        return 'Too many SMS attempts. Please wait a few minutes and try again.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'operation-not-allowed':
        return 'Phone authentication is disabled. Enable Phone provider in Firebase Console > Authentication > Sign-in method.';
      case 'captcha-check-failed':
      case 'invalid-app-credential':
        return 'reCAPTCHA check failed. Ensure localhost or your domain is in Firebase Authorized Domains.';
      case 'quota-exceeded':
        return 'SMS limit reached for this project. Use Firebase Test Phone Numbers for testing.';
      default:
        return e.message ?? 'Something went wrong (${e.code}). Please try again.';
    }
  }
}
