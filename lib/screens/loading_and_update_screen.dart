import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';

class LoadingAndUpdateScreen extends StatefulWidget {
  @override
  State<LoadingAndUpdateScreen> createState() => _LoadingAndUpdateScreenState();
}

class _LoadingAndUpdateScreenState extends State<LoadingAndUpdateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.activeUser != null) {
        await userProvider.selectUser(userProvider.activeUser!);
        if (userProvider.error == null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      body: Center(
        child: userProvider.isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('İçerikler güncelleniyor...'),
                ],
              )
            : userProvider.error != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text(userProvider.error!, style: TextStyle(color: Colors.red)),
                      SizedBox(height: 16),
                      ElevatedButton(
                        child: Text('Tekrar Dene'),
                        onPressed: () async {
                          if (userProvider.activeUser != null) {
                            await userProvider.selectUser(userProvider.activeUser!);
                          }
                        },
                      ),
                    ],
                  )
                : Container(),
      ),
    );
  }
} 