import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../routes.dart';
import '../../../states/global_user.dart';
import '../../../states/locale_store.dart';

class MineTab extends StatefulWidget {
  const MineTab({
    super.key,
    required this.onOpenCurrentTest,
    required this.onOpenVendorTest,
    required this.onOpenOnlineSwitchLock,
  });

  final VoidCallback onOpenCurrentTest;
  final VoidCallback onOpenVendorTest;
  final VoidCallback onOpenOnlineSwitchLock;

  @override
  State<MineTab> createState() => _MineTabState();
}

class _MineTabState extends State<MineTab> {
  String? _username;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    GlobalUser.instance.loadFromStorage().then((_) async {
      if (!mounted) return;
      setState(() {
        _username = GlobalUser.instance.username;
      });
      await GlobalUser.instance.fetchProfile();
      if (!mounted) return;
      setState(() {
        _username = GlobalUser.instance.username ?? GlobalUser.instance.email;
      });
    });
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.confirmLogout),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.logoutAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loggingOut = true);
    try {
      await GlobalUser.instance.logout();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (_) => false);
  }

  Future<void> _openCerebSite() async {
    final url = Uri.parse('http://cereb.ai');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.cannotOpenCerebSite),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeStore = context.watch<LocaleStore>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(l10n.account),
                subtitle: Text(_username ?? '—'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.version),
                subtitle: const Text('1.0.0+1'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: Text(l10n.language),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: localeStore.localeCode,
                    items: LocaleStore.options
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.code,
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      context.read<LocaleStore>().setLocaleCode(value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.science_outlined),
                title: Text(l10n.currentTestHome),
                subtitle: Text(l10n.keepOriginalTestFlow),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onOpenCurrentTest,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.developer_board_outlined),
                title: Text(l10n.vendorSdkTest),
                subtitle: Text(l10n.keepOriginalTestFlow),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onOpenVendorTest,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_open_outlined),
                title: Text(l10n.onlineSwitchLock),
                subtitle: Text(l10n.keepOriginalTestFlow),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onOpenOnlineSwitchLock,
              ),
              const Divider(height: 1),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: _loggingOut ? null : _logout,
          icon: _loggingOut
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
          label: Text(l10n.logout),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${l10n.poweredBy} ',
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            TextButton(
              onPressed: _openCerebSite,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Cereb.AI',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
