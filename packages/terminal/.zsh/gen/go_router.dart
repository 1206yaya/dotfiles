import 'package:go_router/go_router.dart';

GoRouter goRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const HomeScreen();
      },
      routes: [
        GoRoute(
            path: 'home',
            name: 'home',
            builder: (context, state) {
              return const HomeScreen();
            }),
      ],
    )
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false, // debug用のバナーを非表示
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: Colors.grey,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black, // background (button) color
            foregroundColor: Colors.white, // foreground (text) color
          ),
        ),
      ),
      routerConfig: goRouter,
    );
  }
}
