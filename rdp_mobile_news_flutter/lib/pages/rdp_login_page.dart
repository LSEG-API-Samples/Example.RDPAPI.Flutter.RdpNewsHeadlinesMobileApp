import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rdp_mobile_news_flutter/styles/stylepack.dart';
import 'package:rdp_mobile_news_flutter/rdp/rdp_manager.dart' as rdp;
import 'package:rdp_mobile_news_flutter/rdp/rdp_message_data.dart'
    as rdpMsgData;
import 'package:rdp_mobile_news_flutter/pages/rdp_news_mainpage.dart';

Timer myTimer;
bool onLogin = false;

class LoginScreen extends StatefulWidget {
  final rdp.RdpManager rdpMgr = rdp.RdpManager();
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final appKeyController = TextEditingController();
  final loginErrorController = TextEditingController();

  Widget _buildUsernameTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Username',
          style: wbLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            controller: usernameController,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Arial',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.account_box,
                color: Colors.white,
              ),
              hintText: 'Enter Email or Machine Id',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Password',
          style: wbLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            controller: passwordController,
            obscureText: true,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Arial',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.lock,
                color: Colors.white,
              ),
              hintText: 'Enter your Password',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppKeyTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Client ID',
          style: wbLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextField(
            controller: appKeyController,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Arial',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.vpn_key,
                color: Colors.white,
              ),
              hintText: 'Enter client Id or app key',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorTextField() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 10.0),
          Container(
            alignment: Alignment.centerLeft,
            height: 60.0,
            decoration: errorBoxDecorationStyle,
            child: Text(
                loginErrorController.text == null
                    ? ''
                    : loginErrorController.text,
                style: errLabelStyle),
          ),
          SizedBox(height: 10.0)
        ]);
  }

  Widget _buildLoginBtn() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 25.0),
      width: double.infinity,
      child: RaisedButton(
        elevation: 5.0,
        onPressed: () async {
          if (!onLogin) {
            setState(() {
              loginErrorController.text = '';
              onLogin = true;
            });

            print('Login Button Pressed');
            widget.rdpMgr.userName = usernameController.text;
            widget.rdpMgr.userPassword = passwordController.text;
            widget.rdpMgr.clientId = appKeyController.text;
            var tokenResp = await widget.rdpMgr.getAuthenticationInfo(false);
            setState(() {
              onLogin = false;
            });
            if (tokenResp.statusCode == 200) {
              myTimer = Timer.periodic(
                  Duration(
                      seconds: (tokenResp.tokenData.expiresIn * 0.8).round()),
                  (time) async {
                if (tokenResp.tokenData != null &&
                    tokenResp.tokenData.refreshToken != null) {
                  tokenResp = await _getNewToken(
                      tokenResp.tokenData.refreshToken,
                      widget.rdpMgr.userName,
                      widget.rdpMgr.clientId);
                }
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        RdpNewsMainPage(myTimer, widget.rdpMgr)),
              );
            } else {
              print(tokenResp.errorDescription);
              setState(() {
                var errorMsg = '';
                if (tokenResp.errorType != null)
                  errorMsg = '${tokenResp.errorType}:';

                if (tokenResp.errorDescription != null)
                  errorMsg = '$errorMsg ${tokenResp.errorDescription}';
                else if (tokenResp.reasonPhase != null)
                  errorMsg = '$errorMsg ${tokenResp.reasonPhase}';
                loginErrorController.text = errorMsg;
              });
            }
          }
        },
        padding: EdgeInsets.all(15.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        color: Colors.white,
        child: !onLogin
            ? Text(
                'LOGIN',
                style: TextStyle(
                  color: Color(0xFF527DAA),
                  letterSpacing: 1.5,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Arial',
                ),
              )
            : Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<rdpMsgData.TokenResponse> _getNewToken(
      String refreshToken, String userName, String clientId) async {
    var tokenResp = await widget.rdpMgr.getAuthenticationInfo(true,
        refreshToken: refreshToken, userName: userName, clientId: clientId);
    return tokenResp;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
                children: <Widget>[
                  Container(
                    height: double.infinity,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF001EFF),
                          Color(0xFF1C19BD),
                          Color(0xFF121491),
                          Color(0xFF0E0750),
                        ],
                        stops: [0.3, 0.5, 0.7, 0.9],
                      ),
                    ),
                  ),
                  Container(
                    height: double.infinity,
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 40.0,
                        vertical: 120.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Log In',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Arial',
                              fontSize: 30.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 30.0),
                          _buildUsernameTextField(),
                          SizedBox(
                            height: 30.0,
                          ),
                          _buildPasswordTextField(),
                          _buildAppKeyTextField(),
                          _buildErrorTextField(),
                          _buildLoginBtn()
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ));
  }
}
