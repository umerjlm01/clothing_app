import 'dart:developer';

import 'package:zego_zpns/zego_zpns.dart';

class ZPNsEventHandlerManager {
  static loadingEventHandler() {
    ZPNsEventHandler.onRegistered = (ZPNsRegisterMessage registerMessage) {
      log(registerMessage.errorCode.toString());
      log(registerMessage.errorMessage);
      log(registerMessage.pushID);
    };
  }
}