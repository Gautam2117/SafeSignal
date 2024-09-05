import 'package:animated_widgets/widgets/scale_animated.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'admin_screen.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeSignal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF6278ff),
          secondary: Color(0xFF2d3796),
        ),
        brightness: Brightness.dark,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return const AuthScreen(); // If no user, go to the AuthScreen
          } else {
            return HomeScreen(); // If logged in, go to the HomeScreen
          }
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String email = '', password = '', username = '', phoneNumber = '';
  bool isLogin = true;

  // Animation controller for sliding effect
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        UserCredential userCredential = await _auth.signInWithCredential(credential);

        // Save user data to Firestore
        User? user = userCredential.user;
        if (user != null) {
          DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
          if (!doc.exists) {
            // Save new user to Firestore
            await _firestore.collection('users').doc(user.uid).set({
              'username': user.displayName ?? 'Not Provided',
              'email': user.email ?? 'Not Provided',
              'phoneNumber': user.phoneNumber ?? 'Not Provided',
            });
          }
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _signInWithEmail() async {
    try {
      if (isLogin) {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      } else {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        // Save user data to Firestore for email sign up
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'username': username,
          'email': email,
          'phoneNumber': phoneNumber.isEmpty ? 'Not Provided' : phoneNumber,
        });
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _resetPassword() async {
    if (email.isNotEmpty) {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Password reset email sent')));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleLoginSignup() {
    setState(() {
      isLogin = !isLogin;
      if (isLogin) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  if (!isLogin)
                    const SizedBox(height: 10),
                  if (isLogin)
                    const SizedBox(height: 30),
                  ScaleAnimatedWidget(
                    duration: const Duration(seconds: 2),
                    enabled: true,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Safe', // "Safe" in green
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6278ff), // Safety color
                            ),
                          ),
                          TextSpan(
                            text: 'Signal', // "Signal" in red or orange
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Alert color
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLogin)
                    const SizedBox(height: 10),
                  if (isLogin)
                    const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return GlassmorphicContainer(
                        width: MediaQuery.of(context).size.width * 0.85,
                        height: isLogin ? 400 : 500,
                        borderRadius: 20,
                        blur: 20,
                        alignment: Alignment.center,
                        border: 1,
                        linearGradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderGradient: const LinearGradient(
                          colors: [Colors.greenAccent, Colors.redAccent],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!isLogin)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                child: TextField(
                                  onChanged: (value) => setState(() => username = value),
                                  decoration: InputDecoration(
                                    hintText: 'Username',
                                    prefixIcon: const Icon(Icons.person),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.1),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            if (!isLogin)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                child: TextField(
                                  onChanged: (value) => setState(() => phoneNumber = value),
                                  decoration: InputDecoration(
                                    hintText: 'Phone Number',
                                    prefixIcon: const Icon(Icons.phone),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.1),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            if (!isLogin)
                              const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: TextField(
                                onChanged: (value) => setState(() => email = value),
                                decoration: InputDecoration(
                                  hintText: 'Email',
                                  prefixIcon: const Icon(Icons.email),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: TextField(
                                obscureText: true,
                                onChanged: (value) => setState(() => password = value),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  prefixIcon: const Icon(Icons.lock),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (isLogin)
                              TextButton(
                                onPressed: _resetPassword,
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: Colors.blueAccent),
                                ),
                              ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: _signInWithEmail,
                              child: AnimatedContainer(
                                duration: const Duration(seconds: 1),
                                height: 50,
                                width: MediaQuery.of(context).size.width * 0.6,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.blueAccent, Colors.purpleAccent],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    isLogin ? 'Login' : 'Signup',
                                    style: const TextStyle(color: Colors.white, fontSize: 18),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: _signInWithGoogle,
                              child: Container(
                                height: 50,
                                width: MediaQuery.of(context).size.width * 0.6,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 5,
                                      blurRadius: 7,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/google_icon.png',
                                      height: 30,
                                      width: 30,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Sign in with Google',
                                      style: TextStyle(color: Colors.black, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _toggleLoginSignup,
                    child: RichText(
                      text: TextSpan(
                        text: isLogin ? "Don't have an account? " : "Already have an account? ",
                        style: const TextStyle(color: Colors.white),
                        children: <TextSpan>[
                          TextSpan(
                            text: isLogin ? "Signup" : "Login",
                            style: const TextStyle(color: Colors.blueAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => AdminDashboard()),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(seconds: 1),
                      height: 50,
                      width: MediaQuery.of(context).size.width * 0.6,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.redAccent, Colors.orangeAccent],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Login as Admin',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => HomeScreen()),
                      );
                    },
                    child: const Text(
                      'Continue as Guest',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
