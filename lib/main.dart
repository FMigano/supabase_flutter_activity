import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Activity',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Supabase Activity'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Students'),
              Tab(text: 'Courses'),
              Tab(text: 'Enrollments'),
              Tab(text: 'Accounts'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            StudentsTab(),
            CoursesTab(),
            EnrollmentsTab(),
            AccountsTab(),
          ],
        ),
      ),
    );
  }
}

final supabase = Supabase.instance.client;

class StudentsTab extends StatefulWidget {
  const StudentsTab({super.key});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  bool _submitting = false;
  Future<List<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = supabase
          .from('students')
          .select()
          .order('student_id');
    });
  }

  Future<void> _insert() async {
    if (_nameC.text.trim().isEmpty || _emailC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and email required')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await supabase.from('students').insert({
        'full_name': _nameC.text.trim(),
        'email': _emailC.text.trim(),
      });
      _nameC.clear();
      _emailC.clear();
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student added')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameC,
                    decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailC,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _insert,
                    icon: const Icon(Icons.add),
                    label: Text(_submitting ? 'Adding...' : 'Add Student'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final rows = snapshot.data!;
              if (rows.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No students yet'),
                  ),
                );
              }
              return Column(
                children: rows.map((r) {
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${r['student_id']}')),
                      title: Text(r['full_name'] ?? ''),
                      subtitle: Text(r['email'] ?? ''),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class CoursesTab extends StatefulWidget {
  const CoursesTab({super.key});

  @override
  State<CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends State<CoursesTab> {
  final _nameC = TextEditingController();
  final _creditsC = TextEditingController();
  bool _submitting = false;
  Future<List<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = supabase
          .from('courses')
          .select()
          .order('course_id');
    });
  }

  Future<void> _insert() async {
    if (_nameC.text.trim().isEmpty || _creditsC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course name and credits required')));
      return;
    }
    final credits = int.tryParse(_creditsC.text.trim());
    if (credits == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credits must be a number')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await supabase.from('courses').insert({
        'course_name': _nameC.text.trim(),
        'credits': credits,
      });
      _nameC.clear();
      _creditsC.clear();
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course added')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _creditsC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameC,
                    decoration: const InputDecoration(labelText: 'Course name', prefixIcon: Icon(Icons.book)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _creditsC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Credits', prefixIcon: Icon(Icons.numbers)),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _insert,
                    icon: const Icon(Icons.add),
                    label: Text(_submitting ? 'Adding...' : 'Add Course'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final rows = snapshot.data!;
              if (rows.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No courses yet'),
                  ),
                );
              }
              return Column(
                children: rows.map((r) {
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${r['course_id']}')),
                      title: Text(r['course_name'] ?? ''),
                      subtitle: Text('Credits: ${r['credits']}'),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class EnrollmentsTab extends StatefulWidget {
  const EnrollmentsTab({super.key});

  @override
  State<EnrollmentsTab> createState() => _EnrollmentsTabState();
}

class _EnrollmentsTabState extends State<EnrollmentsTab> {
  int? _studentId;
  int? _courseId;
  DateTime _date = DateTime.now();
  bool _submitting = false;

  Future<List<Map<String, dynamic>>>? _future;
  Future<List<Map<String, dynamic>>>? _studentsFuture;
  Future<List<Map<String, dynamic>>>? _coursesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = supabase
          .from('enrollments')
          .select(
              'enrollment_id,enrollment_date,students(full_name),courses(course_name)')
          .order('enrollment_date', ascending: false);
      _studentsFuture = supabase
          .from('students')
          .select('student_id,full_name')
          .order('student_id');
      _coursesFuture = supabase
          .from('courses')
          .select('course_id,course_name')
          .order('course_id');
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _insert() async {
    if (_studentId == null || _courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select student and course')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await supabase.from('enrollments').insert({
        'student_id': _studentId,
        'course_id': _courseId,
        'enrollment_date': _date.toIso8601String().substring(0, 10),
      });
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enrollment added')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _studentsFuture,
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Text('Error: ${snap.error}');
                      }
                      final items = snap.data ?? [];
                      return DropdownButtonFormField<int>(
                        initialValue: _studentId,
                        decoration: const InputDecoration(labelText: 'Student'),
                        items: items.map((s) {
                          return DropdownMenuItem<int>(
                            value: s['student_id'] as int,
                            child: Text(s['full_name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _studentId = v),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _coursesFuture,
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Text('Error: ${snap.error}');
                      }
                      final items = snap.data ?? [];
                      return DropdownButtonFormField<int>(
                        initialValue: _courseId,
                        decoration: const InputDecoration(labelText: 'Course'),
                        items: items.map((c) {
                          return DropdownMenuItem<int>(
                            value: c['course_id'] as int,
                            child: Text(c['course_name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _courseId = v),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Date: ${_date.toIso8601String().substring(0,10)}'),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.date_range),
                        label: const Text('Pick date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _insert,
                    icon: const Icon(Icons.add),
                    label: Text(_submitting ? 'Adding...' : 'Add Enrollment'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final rows = snapshot.data!;
              if (rows.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No enrollments yet'),
                  ),
                );
              }
              return Column(
                children: rows.map((r) {
                  final studentName = (r['students']?['full_name']) ?? 'Student';
                  final courseName = (r['courses']?['course_name']) ?? 'Course';
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${r['enrollment_id']}')),
                      title: Text('$studentName → $courseName'),
                      subtitle: Text('Date: ${r['enrollment_date']}'),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AccountsTab extends StatefulWidget {
  const AccountsTab({super.key});

  @override
  State<AccountsTab> createState() => _AccountsTabState();
}

class _AccountsTabState extends State<AccountsTab> {
  int? _studentId;
  final _usernameC = TextEditingController();
  final _passwordC = TextEditingController();
  String _role = 'student';
  bool _submitting = false;
  Future<List<Map<String, dynamic>>>? _future;
  Future<List<Map<String, dynamic>>>? _studentsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = supabase
          .from('accounts')
          .select('account_id,username,role,students(full_name,student_id)')
          .order('account_id');
      _studentsFuture = supabase
          .from('students')
          .select('student_id,full_name')
          .order('student_id');
    });
  }

  Future<void> _insert() async {
    if (_studentId == null || _usernameC.text.trim().isEmpty || _passwordC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All fields required')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await supabase.from('accounts').insert({
        'student_id': _studentId,
        'username': _usernameC.text.trim(),
        'password': _passwordC.text,
        'role': _role,
      });
      _usernameC.clear();
      _passwordC.clear();
      _role = 'student';
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account added')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _usernameC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _studentsFuture,
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Text('Error: ${snap.error}');
                      }
                      final items = snap.data ?? [];
                      return DropdownButtonFormField<int>(
                        initialValue: _studentId,
                        decoration: const InputDecoration(labelText: 'Student'),
                        items: items.map((s) {
                          return DropdownMenuItem<int>(
                            value: s['student_id'] as int,
                            child: Text(s['full_name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _studentId = v),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameC,
                    decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.badge)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordC,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(value: 'student', child: Text('student')),
                      DropdownMenuItem(value: 'admin', child: Text('admin')),
                    ],
                    onChanged: (v) => setState(() => _role = v ?? 'student'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _insert,
                    icon: const Icon(Icons.add),
                    label: Text(_submitting ? 'Adding...' : 'Add Account'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final rows = snapshot.data!;
              if (rows.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No accounts yet'),
                  ),
                );
              }
              return Column(
                children: rows.map((r) {
                  final student = r['students'];
                  final label = student != null ? '${student['full_name']} (#${student['student_id']})' : 'Student';
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${r['account_id']}')),
                      title: Text(r['username'] ?? ''),
                      subtitle: Text('Role: ${r['role']} • $label'),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}