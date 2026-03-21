import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:get/get.dart';
import 'package:mobile_app/ui/views/base_view.dart';
import 'package:mobile_app/ui/views/cv_landing_view.dart';
import 'package:mobile_app/utils/snackbar_utils.dart';
import 'package:mobile_app/viewmodels/authentication/auth_options_viewmodel.dart';
import 'package:mobile_app/viewmodels/authentication/new_auth_options_viewmodel.dart';

class AuthOptionsView extends StatefulWidget {
  const AuthOptionsView({super.key, this.isSignUp = false});

  final bool isSignUp;

  @override
  _AuthOptionsViewState createState() => _AuthOptionsViewState();
}

class _AuthOptionsViewState extends State<AuthOptionsView> {
  late AuthOptionsViewModel _model;
  late NewAuthOptionsViewModel _newAuthModel;

  Future<void> onNewGoogleAuthPressed() async {
    await _newAuthModel.signInWithGoogle();

    if (_newAuthModel.isSuccess(_newAuthModel.FIREBASE_GOOGLE_AUTH)) {
      final userName = _newAuthModel.getUserName();
      SnackBarUtils.showDark(
        'Login Successful',
        'Welcome ${userName ?? 'User'}!',
      );
      await Get.offAllNamed(CVLandingView.id);
    } else if (_newAuthModel.isError(_newAuthModel.FIREBASE_GOOGLE_AUTH)) {
      SnackBarUtils.showDark(
        'Google Sign-In Error',
        _newAuthModel.errorMessageFor(_newAuthModel.FIREBASE_GOOGLE_AUTH),
      );
    }
  }

  Future<void> onGithubAuthPressed() async {
    await _model.githubAuth(isSignUp: widget.isSignUp);

    if (_model.isSuccess(_model.GITHUB_OAUTH)) {
      await Get.offAllNamed(CVLandingView.id);
    } else if (_model.isError(_model.GITHUB_OAUTH)) {
      SnackBarUtils.showDark(
        'GitHub Authentication Error',
        _model.errorMessageFor(_model.GITHUB_OAUTH),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<NewAuthOptionsViewModel>(
      onModelReady: (newAuthModel) {
        _newAuthModel = newAuthModel;
        // Initialize the old auth model for GitHub
        _model = AuthOptionsViewModel();
      },
      builder:
          (context, newAuthModel, child) => Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 32),
                child: Row(
                  children: <Widget>[
                    const Expanded(child: Divider(thickness: 1)),
                    Text('  Or ${widget.isSignUp ? 'SignUp' : 'Login'} with  '),
                    const Expanded(child: Divider(thickness: 1)),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  GestureDetector(
                    onTap: onNewGoogleAuthPressed,
                    child: Container(
                      padding: const EdgeInsetsDirectional.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/icons/google_icon.png',
                            height: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text("Sign in with Google"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: onGithubAuthPressed,
                    child: Container(
                      padding: const EdgeInsetsDirectional.all(8),
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: const Icon(FontAwesome5.github, size: 40),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }
}
