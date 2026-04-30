// AI生成 - 登录/注册页面，使用手机号作为账号
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _loginPhone = TextEditingController();
  final _loginPass = TextEditingController();
  final _regPhone = TextEditingController();
  final _regPass = TextEditingController();
  final _regPass2 = TextEditingController();
  bool _obscureLogin = true;
  bool _obscureReg = true;
  bool _obscureReg2 = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _loginPhone.dispose();
    _loginPass.dispose();
    _regPhone.dispose();
    _regPass.dispose();
    _regPass2.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    final err = await ref.read(userProvider.notifier).login(
          _loginPhone.text,
          _loginPass.text,
        );
    if (err != null) {
      _showError(err);
    } else {
      _showSuccess('登录成功');
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _doRegister() async {
    if (_regPass.text != _regPass2.text) {
      _showError('两次密码不一致');
      return;
    }
    final err = await ref.read(userProvider.notifier).register(
          _regPhone.text,
          _regPass.text,
        );
    if (err != null) {
      _showError(err);
    } else {
      _showSuccess('注册成功，已自动登录');
      if (mounted) Navigator.pop(context, true);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('登录 / 注册')),
      body: Column(
        children: [
          const SizedBox(height: 24),
          // Logo
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(Icons.school, size: 40, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 12),
          Text('StudyMate Pro', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text('使用手机号注册/登录', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          // Tab bar
          TabBar(
            controller: _tabCtrl,
            tabs: const [Tab(text: '登录'), Tab(text: '注册')],
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildLoginTab(theme),
                _buildRegisterTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          TextField(
            controller: _loginPhone,
            decoration: const InputDecoration(
              labelText: '手机号',
              prefixIcon: Icon(Icons.phone_android),
              hintText: '请输入11位手机号',
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _loginPass,
            obscureText: _obscureLogin,
            decoration: InputDecoration(
              labelText: '密码',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureLogin ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureLogin = !_obscureLogin),
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _doLogin(),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _doLogin,
            icon: const Icon(Icons.login),
            label: const Text('登录'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => _tabCtrl.animateTo(1),
              child: const Text('没有账号？去注册'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          TextField(
            controller: _regPhone,
            decoration: const InputDecoration(
              labelText: '手机号',
              prefixIcon: Icon(Icons.phone_android),
              hintText: '手机号即为您的登录账号',
              helperText: '请输入11位手机号，以1开头',
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _regPass,
            obscureText: _obscureReg,
            decoration: InputDecoration(
              labelText: '密码',
              prefixIcon: const Icon(Icons.lock_outline),
              hintText: '至少6位',
              suffixIcon: IconButton(
                icon: Icon(_obscureReg ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureReg = !_obscureReg),
              ),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _regPass2,
            obscureText: _obscureReg2,
            decoration: InputDecoration(
              labelText: '确认密码',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureReg2 ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureReg2 = !_obscureReg2),
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _doRegister(),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _doRegister,
            icon: const Icon(Icons.person_add),
            label: const Text('注册'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => _tabCtrl.animateTo(0),
              child: const Text('已有账号？去登录'),
            ),
          ),
        ],
      ),
    );
  }
}
