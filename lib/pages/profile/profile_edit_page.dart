// AI生成 - 个人资料编辑页，支持修改昵称、头像（内置+自定义上传）、个性签名、个人标签
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../providers/user_provider.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  late TextEditingController _nickCtrl;
  late TextEditingController _bioCtrl;
  final _tagCtrl = TextEditingController();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _nickCtrl = TextEditingController(text: user?.nickname ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _nickCtrl.dispose();
    _bioCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
    ));
  }

  /// 从相册选择图片作为头像
  Future<void> _pickAvatarImage(UserNotifier notifier) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;

      // 复制到应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${appDir.path}/avatars');
      if (!await avatarDir.exists()) await avatarDir.create(recursive: true);

      final ext = p.extension(picked.path);
      final destPath = '${avatarDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}$ext';
      await File(picked.path).copy(destPath);

      notifier.updateAvatarPath(destPath);
    } catch (e) {
      _showMsg('选择图片失败：$e', isError: true);
    }
  }

  /// 构建头像显示 Widget
  Widget _buildAvatarWidget(ThemeData theme, String? avatarPath, int avatarIndex) {
    if (avatarPath != null && avatarPath.isNotEmpty && File(avatarPath).existsSync()) {
      return CircleAvatar(
        radius: 48,
        backgroundImage: FileImage(File(avatarPath)),
      );
    }
    return CircleAvatar(
      radius: 48,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        UserNotifier.avatarAssets[avatarIndex],
        style: const TextStyle(fontSize: 40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(userProvider);
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('编辑资料')),
        body: const Center(child: Text('请先登录')),
      );
    }

    final notifier = ref.read(userProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑资料'),
        actions: [
          TextButton(
            onPressed: () async {
              final nickErr = await notifier.updateNickname(_nickCtrl.text);
              if (nickErr != null) { _showMsg(nickErr, isError: true); return; }
              final bioErr = await notifier.updateBio(_bioCtrl.text);
              if (bioErr != null) { _showMsg(bioErr, isError: true); return; }
              if (context.mounted) Navigator.pop(context);
              _showMsg('保存成功');
            },
            child: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 头像选择区域
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _showAvatarPicker(context, user.avatarIndex, user.avatarPath, notifier),
                  child: Stack(
                    children: [
                      _buildAvatarWidget(theme, user.avatarPath, user.avatarIndex),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primary,
                          child: Icon(Icons.camera_alt, size: 16, color: theme.colorScheme.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('点击更换头像', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 基本信息
          Text('基本信息', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _nickCtrl,
            decoration: const InputDecoration(
              labelText: '昵称',
              prefixIcon: Icon(Icons.badge_outlined),
              hintText: '给自己取一个好听的名字',
            ),
            maxLength: 20,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bioCtrl,
            decoration: const InputDecoration(
              labelText: '个性签名',
              prefixIcon: Icon(Icons.edit_note),
              hintText: '写一句话来介绍自己吧',
            ),
            maxLength: 50,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          TextField(
            enabled: false,
            decoration: const InputDecoration(
              labelText: '手机号（账号）',
              prefixIcon: Icon(Icons.phone_android),
            ),
            controller: TextEditingController(text: user.username),
          ),
          const SizedBox(height: 24),

          // 个人标签
          Row(
            children: [
              Text('个人标签', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAddTagDialog(context, notifier),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (user.tags.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.label_outline, size: 32, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                    const SizedBox(height: 8),
                    Text('还没有标签，点击上方添加', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.tags.map((tag) => Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => notifier.removeTag(tag),
                backgroundColor: theme.colorScheme.secondaryContainer,
                labelStyle: TextStyle(color: theme.colorScheme.onSecondaryContainer),
              )).toList(),
            ),
          const SizedBox(height: 16),
          // 预设标签快速添加
          Text('推荐标签', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedTags
                .where((t) => !user.tags.contains(t))
                .map((tag) => ActionChip(
                      label: Text('+ $tag'),
                      onPressed: () async {
                        final err = await notifier.addTag(tag);
                        if (err != null) _showMsg(err, isError: true);
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  static const _suggestedTags = [
    '考研党', '大一', '大二', '大三', '大四',
    '计算机', '软件工程', '人工智能', '数学',
    '英语达人', '早起鸟', '夜猫子', '自律达人',
    '刷题狂人', '阅读爱好者', '效率控', '极简主义',
  ];

  void _showAvatarPicker(BuildContext context, int current, String? currentPath, UserNotifier notifier) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('选择头像', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                // 从相册上传按钮
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _pickAvatarImage(notifier);
                  },
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('从相册选择'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('内置头像', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: UserNotifier.avatarAssets.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () {
                  notifier.updateAvatarIndex(i);
                  Navigator.pop(ctx);
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (currentPath == null || currentPath.isEmpty) && i == current
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    border: (currentPath == null || currentPath.isEmpty) && i == current
                        ? Border.all(color: theme.colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(UserNotifier.avatarAssets[i], style: const TextStyle(fontSize: 24)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddTagDialog(BuildContext context, UserNotifier notifier) {
    _tagCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加标签'),
        content: TextField(
          controller: _tagCtrl,
          decoration: const InputDecoration(
            hintText: '输入自定义标签',
            prefixIcon: Icon(Icons.label_outline),
          ),
          maxLength: 10,
          autofocus: true,
          onSubmitted: (v) async {
            if (v.trim().isNotEmpty) {
              final err = await notifier.addTag(v.trim());
              if (err != null) {
                _showMsg(err, isError: true);
              } else {
                if (ctx.mounted) Navigator.pop(ctx);
              }
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              if (_tagCtrl.text.trim().isNotEmpty) {
                final err = await notifier.addTag(_tagCtrl.text.trim());
                if (err != null) {
                  _showMsg(err, isError: true);
                } else {
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}
