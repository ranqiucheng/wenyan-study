import "package:flutter/material.dart";

import "../services/card_store.dart";
import "../services/settings_store.dart";
import "../services/stats_store.dart";
import "../services/wrong_store.dart";
import "../theme.dart";
import "home_page.dart";
import "profile_page.dart";
import "quiz_page.dart";
import "training_page.dart";
import "review_page.dart";

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    CardStore.instance.load();
    WrongStore.instance.load();
    SettingsStore.instance.load();
    StatsStore.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomePage(),
          ReviewPage(),
          QuizPage(),
          TrainingPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        backgroundColor: kCard,
        indicatorColor: kPale,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: "读"),
          NavigationDestination(icon: Icon(Icons.style_outlined), selectedIcon: Icon(Icons.style), label: "背"),
          NavigationDestination(icon: Icon(Icons.edit_note_outlined), selectedIcon: Icon(Icons.edit_note), label: "练"),
          NavigationDestination(icon: Icon(Icons.lightbulb_outline), selectedIcon: Icon(Icons.lightbulb), label: "训"),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: "我"),
        ],
      ),
    );
  }
}
