import 'dart:async';
import 'dart:developer';
import 'package:clothing_app/bloc/bloc.dart';
import 'package:clothing_app/screens/profilepage/profile_models.dart';
import 'package:clothing_app/utils/constant_strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../utils/secure_storage.dart';

class ProfileBloc extends Bloc {
  final BuildContext context;
  final State<StatefulWidget> state;

  ProfileBloc(this.context, this.state);

  final supabase = Supabase.instance.client;

  //Profile

  final _storage = SecureStorage();

  // Profile

  Future<Profile> getProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await supabase
          .from(ConstantStrings.profileTable)
          .select()
          .eq('id', userId)
          .single(); // 👈 ensures one row

      return Profile.fromJson(response);
    } catch (e) {
      log('ProfileBloc getProfile catch $e');
      rethrow; // 👈 propagate error properly
    }
  }


  Future<void> logout() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null){
        await supabase.from(ConstantStrings.profileTable).update({
          'fcm_token': null,
        }).eq('id', userId);
      }
      ZegoUIKitPrebuiltCallInvitationService().uninit();
      await supabase.auth.signOut();
      await _storage.delete('accessToken');
      log('Logout successful');
    } catch (e, t) {
      log('Logout failed: $e \n $t');
    }
  }





  @override
  void dispose() {
    // TODO: implement dispose

  }
}
