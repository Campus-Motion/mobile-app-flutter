import 'package:flutter/material.dart';

class TopAppBar extends StatelessWidget {

  const TopAppBar({
    super.key
  });

  @override build(BuildContext contex){
    return Container(
      padding: EdgeInsetsGeometry.all(20),
      child : Row(children: [
        Image(
          width: 150,
          image: AssetImage('assets/images/logo_peach.png')
          ),

        Spacer(flex: 1),

        Image(
          width: 50,
          image: AssetImage('assets/images/splash-icon.png'),
        )

      ],)
    );
  }

}