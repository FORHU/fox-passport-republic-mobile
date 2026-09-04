import 'package:flutter_template/features/quiz/data/models/quiz_question_model.dart';

const List<QuizQuestionModel> kLocalFlutterQuizQuestions = [
  QuizQuestionModel(
    id: 201,
    category: 'RIVERPOD',
    difficulty: 'BEGINNER',
    question:
        'In Flutter Riverpod, what is the recommended widget to extend when a component needs to read or listen to providers?',
    codeSnippet:
        'class MyWidget extends ConsumerWidget {\n  @override\n  Widget build(BuildContext context, WidgetRef ref) {\n    final user = ref.watch(userProvider);\n    return Text(user.name);\n  }\n}',
    options: [
      'StatefulWidget with ProviderStateMixin',
      'ConsumerWidget (or ConsumerStatefulWidget for local state)',
      'InheritedWidget with ProviderScope',
      'StatelessWidget with context.dependOnInheritedWidgetOfExactType()'
    ],
    correctIndex: 1,
    explanation:
        'ConsumerWidget provides a WidgetRef parameter in its build method, enabling straightforward, reactive provider watching without boilerplate.',
  ),
  QuizQuestionModel(
    id: 202,
    category: 'WIDGET_LIFECYCLE',
    difficulty: 'BEGINNER',
    question:
        'Which method in a State object is called exactly once when the widget is inserted into the tree?',
    codeSnippet:
        'class _MyScreenState extends State<MyScreen> {\n  @override\n  void initState() {\n    super.initState();\n    // initialization logic\n  }\n}',
    options: [
      'didUpdateWidget()',
      'didChangeDependencies()',
      'initState()',
      'build()'
    ],
    correctIndex: 2,
    explanation:
        'initState() is called once and only once when the State object is inserted into the tree, making it ideal for one-time initialization.',
  ),
  QuizQuestionModel(
    id: 203,
    category: 'STATE_MANAGEMENT',
    difficulty: 'INTERMEDIATE',
    question:
        'What is the primary difference between ref.watch() and ref.read() in Riverpod?',
    codeSnippet:
        '// Usage A\nfinal count = ref.watch(counterProvider);\n// Usage B\nref.read(counterProvider.notifier).increment();',
    options: [
      'ref.watch() is asynchronous while ref.read() is synchronous.',
      'ref.watch() subscribes to changes and rebuilds the widget; ref.read() obtains the value once without rebuilding.',
      'ref.read() can only be called inside build(), whereas ref.watch() can be used anywhere.',
      'ref.read() creates a new provider instance; ref.watch() reuses an existing one.'
    ],
    correctIndex: 1,
    explanation:
        'ref.watch() registers a reactive listener that triggers widget rebuilds when state updates. ref.read() simply reads the current value and is recommended inside callbacks (e.g. onPressed).',
  ),
  QuizQuestionModel(
    id: 204,
    category: 'PERFORMANCE',
    difficulty: 'INTERMEDIATE',
    question:
        'Why is using const constructors heavily recommended throughout Flutter widget trees?',
    codeSnippet: 'const SizedBox(height: 16)',
    options: [
      'It forces widgets to run on a background isolate.',
      'It compiles widgets directly to native C++ code.',
      'It allows Flutter to canonicalize instances and skip unnecessary rebuilds during reconciliation.',
      'It disables layout passes completely for that subtree.'
    ],
    correctIndex: 2,
    explanation:
        'const constructors allow Flutter to reuse widget instances, short-circuiting element tree diffing and eliminating redundant allocations during rebuilds.',
  ),
  QuizQuestionModel(
    id: 205,
    category: 'NAVIGATION',
    difficulty: 'INTERMEDIATE',
    question:
        'In GoRouter, how do you perform declarative routing that replaces the current URL instead of pushing onto the history stack?',
    codeSnippet:
        'context.go(RouteNames.home); // vs context.push(RouteNames.home);',
    options: [
      'context.push()',
      'context.go()',
      'Navigator.of(context).pushNamed()',
      'context.popAndPushNamed()'
    ],
    correctIndex: 1,
    explanation:
        'context.go() changes the matched location declaratively according to routing configuration, matching browser URL history behavior.',
  ),
  QuizQuestionModel(
    id: 206,
    category: 'DART_PATTERNS',
    difficulty: 'ADVANCED',
    question:
        'Dart 3 introduced exhaustive pattern matching. What happens if a switch expression over a sealed class omits a subclass?',
    codeSnippet:
        'sealed class Result {}\nclass Success extends Result {}\nclass Failure extends Result {}\n\nString handle(Result r) => switch (r) {\n  Success() => "OK",\n  // Missing Failure()\n};',
    options: [
      'It defaults to returning null at runtime.',
      'The compiler raises a compile-time error because pattern matching on sealed classes must be exhaustive.',
      'It throws a FallThroughError at runtime.',
      'It silently skips execution of that function.'
    ],
    correctIndex: 1,
    explanation:
        'Sealed classes in Dart 3 guarantee compile-time exhaustiveness: the compiler verifies that all possible subtypes are covered in switch expressions.',
  ),
  QuizQuestionModel(
    id: 207,
    category: 'ASYNCHRONY',
    difficulty: 'ADVANCED',
    question:
        'When performing compute-heavy JSON parsing or encryption in Flutter, how should work be offloaded from the UI thread?',
    codeSnippet:
        'final parsedData = await compute(parseLargeJsonPayload, rawJsonString);',
    options: [
      'By wrapping the function in Future.delayed(Duration.zero)',
      'By using Flutter Isolates or the top-level compute() helper',
      'By running the operation in Microtask queue via scheduleMicrotask()',
      'By calling setState() before and after the calculation'
    ],
    correctIndex: 1,
    explanation:
        'Flutter runs on a single event loop. Heavy CPU tasks block the main isolate (causing jank/frame drops) unless spawned onto a separate worker isolate via compute() or Isolate.run().',
  ),
  QuizQuestionModel(
    id: 208,
    category: 'NETWORKING',
    difficulty: 'INTERMEDIATE',
    question: 'In Dio, what is the purpose of an Interceptor?',
    codeSnippet:
        'dio.interceptors.add(InterceptorsWrapper(\n  onRequest: (options, handler) {\n    options.headers["Authorization"] = "Bearer \$token";\n    return handler.next(options);\n  },\n));',
    options: [
      'To compile HTTP endpoints into WebAssembly.',
      'To intercept, inspect, and transform HTTP requests, responses, and errors (such as attaching auth tokens or handling 401 refresh).',
      'To replace TCP sockets with raw UDP packets.',
      'To bypass SSL certificate validation in production.'
    ],
    correctIndex: 1,
    explanation:
        'Dio interceptors provide hooks for onRequest, onResponse, and onError, allowing centralized token injection, retry logic, logging, and error normalization.',
  ),
  QuizQuestionModel(
    id: 209,
    category: 'ANIMATIONS',
    difficulty: 'INTERMEDIATE',
    question:
        'What is the role of an AnimationController in explicit Flutter animations?',
    codeSnippet:
        'final controller = AnimationController(\n  duration: const Duration(milliseconds: 300),\n  vsync: this,\n);',
    options: [
      'It only draws SVG vector frames.',
      'It generates animation values (typically 0.0 to 1.0) over a duration, driven by a Ticker that syncs with screen refresh.',
      'It controls device GPU clock frequencies.',
      'It manages audio playback speed.'
    ],
    correctIndex: 1,
    explanation:
        'An AnimationController produces numbers from 0.0 to 1.0 (or custom bounds) over a given duration, using a Ticker to generate values once per frame.',
  ),
  QuizQuestionModel(
    id: 210,
    category: 'ARCHITECTURE',
    difficulty: 'EXPERT',
    question:
        'In Clean Architecture for Flutter, why should domain entities and use cases have zero dependencies on external packages like Dio or SharedPreferences?',
    codeSnippet:
        '// Domain Entity\nclass User {\n  final String id;\n  final String email;\n  const User({required this.id, required this.email});\n}',
    options: [
      'Because Dart cannot import external libraries inside classes.',
      'To enforce the Dependency Inversion Principle, ensuring core business rules remain pure, testable, and decoupled from framework or database changes.',
      'Because Flutter build tools will fail if external packages are imported in lib/domain.',
      'To enable automatic conversion to Objective-C.'
    ],
    correctIndex: 1,
    explanation:
        'The domain layer contains essential business rules and must remain independent of UI, third-party libraries, and datasources. External details depend on domain abstractions, never the reverse.',
  ),
];
