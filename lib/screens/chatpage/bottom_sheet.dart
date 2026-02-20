import 'package:clothing_app/screens/chatpage/chat_bloc.dart';
import 'package:flutter/material.dart';
import 'package:clothing_app/reusable_widgets/icon_button.dart';
import 'package:clothing_app/utils/constant_variables.dart';

class CustomBottomSheet extends StatefulWidget {
  const CustomBottomSheet({super.key, required this.bloc});
  final ChatScreenBloc bloc;

  @override
  State<CustomBottomSheet> createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet> {

  ChatScreenBloc  get _bloc => widget.bloc;

  @override
  void initState() {
    super.initState();
  }




  Widget buildItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  })
  {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: deviceHeight * 0.065,
          width: deviceHeight * 0.065,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: AppIconButton(
              onPressed: onTap,
              icon: Icon(
                icon,
                color: iconColor,
                size: deviceHeight / 50,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: deviceWidth * 0.05,
        vertical: deviceHeight * 0.02,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB), // soft white background
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// 🔹 Drag Indicator
          Container(
            height: 5,
            width: 40,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 20,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
            children: [
              buildItem(icon: Icons.photo, label: "Gallery", iconColor: Colors.blue, onTap: () { _bloc.imageHandler.pickImage();
              Navigator.pop(context);
              }),
              buildItem(icon: Icons.camera_alt, label: "Camera", iconColor: Colors.pink, onTap: () { _bloc.imageHandler.pickImageFromCamera();
              Navigator.pop(context);}),
              buildItem(icon: Icons.location_on, label: "Location", iconColor: Colors.green, onTap: () {_bloc.mapsHandler.getCurrentLocation();
              Navigator.pop(context);}),
              buildItem(icon: Icons.person, label: "Contact", iconColor: Colors.teal, onTap: (){_bloc.contactHandler.pickContact();
              Navigator.pop(context);}),
              buildItem(icon: Icons.insert_drive_file, label: "Document", iconColor: Colors.deepPurple, onTap: (){_bloc.documentHandler.pickDocument();
              Navigator.pop(context);}),
              buildItem(icon: Icons.headset, label: "Audio", iconColor: Colors.orange, onTap: (){_bloc.audioHandler.pickAudio();
              Navigator.pop(context);}),
              // buildItem(icon: Icons.poll, label: "Poll", iconColor: Colors.amber, onTap: () {}),
              // buildItem(icon: Icons.event, label: "Event", iconColor: Colors.pinkAccent, onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}
