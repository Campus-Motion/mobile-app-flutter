import 'package:flutter/material.dart';
import 'package:mobile_app/config/routes.dart';
import 'package:mobile_app/widgets/master_container.dart';
import 'package:mobile_app/widgets/top_bar.dart';
import 'package:mobile_app/widgets/bottom_bar.dart';

class ProfileIndexScreen extends StatelessWidget {
  const ProfileIndexScreen({super.key});

  static dynamic _navigationFunction(BuildContext context, int index){
    switch(index) {
      case 0 : 
        return Navigator.pushNamed(context, AppRoutes.dashboard);
      case 1 :
        return Navigator.pushNamed(context, AppRoutes.trail);
      case 2 :
        return Navigator.pushNamed(context, AppRoutes.social);
      case 3 : 
        return Navigator.pushNamed(context, AppRoutes.profile);
      case _ :
        return Navigator.pushNamed(context, AppRoutes.dashboard);
    }
  }
  @override
  Widget build(BuildContext context) {
    return MasterContainer(
      bottomNavigationBar: CampusMotionBottomBar(currentIndex: 3, onTap: _navigationFunction, context: context),
      children : [
        TopAppBar(),
        SizedBox(height: 20),
       Padding(
        padding:EdgeInsetsGeometry.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage('assets/images/splash-icon.png'),
                  radius: 35
                  ),
                  SizedBox(width:40),
                  Column(children: [
                    Text(
                    'Forrest Gump',
                    style: TextStyle(fontSize:20)
                  ),
                  Text(
                    'EPFL Student',
                    style: TextStyle(color:Colors.blueGrey)
                  )
                  ],)
                 
            ],),
            SizedBox(height:20),
            Container(
              height:80,
              width:400,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                "Mom always said : Life is like a box of chocolate...",
                textAlign: TextAlign.center)
            ),
            SizedBox(height:20),
            Container(
              height:200,
              width:400,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                "Performance : Ran through the United States \n Streak : 735 days",
                textAlign: TextAlign.center)
            )
        ],)
       ),
      ]
    );
  }
}
