import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactHandler {
  final ValueNotifier<Contact?> _contactNotifier = ValueNotifier<Contact?>(null);
  ValueNotifier<Contact?> get contactNotifier => _contactNotifier;

  /// Pick a contact (UI-blind)
  Future<void> pickContact() async {
    try {
      final FlutterNativeContactPicker contactPicker = FlutterNativeContactPicker();
      final status = await Permission.contacts.request();

      if (status == PermissionStatus.granted) {
        final selected = await contactPicker.selectContact();
        if (selected != null) {
          _contactNotifier.value = selected;
          log('ContactHandler: Contact selected -> ${selected.fullName}');
        } else {
          _contactNotifier.value = null;
          log('ContactHandler: No contact selected');
        }
      } else {
        log('ContactHandler: Permission denied');
      }
    } catch (e, t) {
      log('ContactHandler pickContact error: $e \n $t');
    }
  }

  /// Clear picked contact after sending
  void clear() {
    _contactNotifier.value = null;
    log('ContactHandler: cleared picked contact');
  }
}
