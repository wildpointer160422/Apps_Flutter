import 'package:english_words/english_words.dart'; // 添加这一行
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:numberpicker/numberpicker.dart'; // 添加这一行

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: Color.fromARGB(235, 29, 163, 100)),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var favorites = <WordPair>[];
  List<Clock> clocks = [];
  Timer? timer;

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }

  void addClock(String name, Duration countdownDuration) {
    final newClock = Clock(
      name: name,
      time: DateTime.now(),
      countdownDuration: countdownDuration,
    );
    clocks.add(newClock);
    notifyListeners();
  }

  void removeClock(Clock clock) {
    clocks.remove(clock); // 通过 clock 对象删除
    notifyListeners();
  }

  void startTimer(BuildContext context) {
    bool hasRunningClocks =
        clocks.any((clock) => clock.isRunning && !clock.isPaused);

    if (!hasRunningClocks) {
      timer?.cancel();
      timer = null;
    } else {
      if (timer == null || !timer!.isActive) {
        timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
          for (var clock in clocks) {
            if (clock.isRunning && !clock.isPaused) {
              clock.decrementTime();
              if (clock.isCompleted() && !clock.isDialogShown) {
                _showCompletionDialog(clock, context);
                clock.isDialogShown = true; // 设置对话框已弹出
              }
            }
          }
          notifyListeners();
        });
      }
    }
  }

  void _showCompletionDialog(Clock clock, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${clock.name} 已完成'),
          actions: [
            TextButton(
              onPressed: () {
                removeClock(clock); // 直接传递 clock 对象
                Navigator.of(context).pop(); // 关闭对话框
              },
              child: Text('确定'),
            ),
          ],
        );
      },
    );
  }
}

class Clock {
  String name;
  DateTime time;
  Duration countdownDuration;
  Duration remainingTime;
  bool isRunning;
  bool isPaused;
  bool isDialogShown; // 新增字段：判断是否弹出过对话框

  Clock({
    required this.name,
    required this.time,
    required this.countdownDuration,
    this.remainingTime = const Duration(),
    this.isRunning = false,
    this.isPaused = true, // 初始状态设为暂停
    this.isDialogShown = false, // 默认没有弹出对话框
  }) {
    remainingTime = countdownDuration;
  }

  void start() {
    if (!isRunning && !isPaused) {
      isRunning = true;
      remainingTime = countdownDuration; // 重置剩余时间
      isPaused = false; // 确保恢复时暂停状态为 false
    }
  }

  void pause() {
    if (isRunning && !isPaused) {
      isPaused = true;
    }
  }

  void resume() {
    if (isRunning && isPaused) {
      isPaused = false;
    }
  }

  void reset() {
    isRunning = false;
    isPaused = false;
    remainingTime = countdownDuration; // 重置剩余时间
  }

  bool isCompleted() {
    return remainingTime.inSeconds <= 0; // 倒计时完成
  }

  void decrementTime() {
    if (isRunning && !isPaused && remainingTime.inSeconds > 0) {
      remainingTime -= Duration(seconds: 1);
    }
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = PageOne();
        break;
      case 1:
        page = Placeholder(); // 这里可以替换为你想要的第二个页面
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Page 1'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings),
                    label: Text('Settings'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class SetCountdownPage extends StatefulWidget {
  final Function(Duration) onSet;

  SetCountdownPage({required this.onSet});

  @override
  _SetCountdownPageState createState() => _SetCountdownPageState();
}

class _SetCountdownPageState extends State<SetCountdownPage> {
  int hours = 0;
  int minutes = 0;
  int seconds = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Countdown'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: NumberPicker(
                    value: hours,
                    minValue: 0,
                    maxValue: 24,
                    onChanged: (value) => setState(() => hours = value),
                  ),
                ),
                Expanded(
                  child: NumberPicker(
                    value: minutes,
                    minValue: 0,
                    maxValue: 59,
                    onChanged: (value) => setState(() => minutes = value),
                  ),
                ),
                Expanded(
                  child: NumberPicker(
                    value: seconds,
                    minValue: 0,
                    maxValue: 59,
                    onChanged: (value) => setState(() => seconds = value),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Duration duration = Duration(
                  hours: hours,
                  minutes: minutes,
                  seconds: seconds,
                );
                widget.onSet(duration); // 调用回调传递计时器时间
                Navigator.of(context).pop();
              },
              child: Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}

class PageOne extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page One'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              String? clockName = await _showNameDialog(context);
              if (clockName != null && clockName.isNotEmpty) {
                Duration? selectedDuration = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SetCountdownPage(
                      onSet: (duration) {
                        Provider.of<MyAppState>(context, listen: false)
                            .addClock(clockName, duration);
                      },
                    ),
                  ),
                );
              }
            },
          )
        ],
      ),
      body: Consumer<MyAppState>(builder: (context, state, child) {
        return ListView.builder(
          itemCount: state.clocks.length,
          itemBuilder: (context, index) {
            final clock = state.clocks[index];
            return ListTile(
              title: Text(clock.name),
              subtitle: clock.isCompleted()
                  ? Text('已完成')
                  : Text(formatDuration(clock.remainingTime)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.delete),
                    color: Colors.red,
                    onPressed: () {
                      // 传递 clock 对象，而不是 index
                      Provider.of<MyAppState>(context, listen: false)
                          .removeClock(state.clocks[index]);
                    },
                  ),
                  IconButton(
                    icon: Icon(clock.isPaused ? Icons.play_arrow : Icons.pause),
                    onPressed: () {
                      if (!clock.isRunning) {
                        clock.start(); // 启动计时器
                      } else {
                        clock.isPaused
                            ? clock.resume()
                            : clock.pause(); // 切换暂停和继续
                      }
                      Provider.of<MyAppState>(context, listen: false)
                          .startTimer(context); // 开始计时器
                    },
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Future<String?> _showNameDialog(BuildContext context) async {
    TextEditingController _controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Timer Name'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: 'Timer Name'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(_controller.text); // 返回用户输入的名称
              },
            ),
          ],
        );
      },
    );
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
