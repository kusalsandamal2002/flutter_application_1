import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../controllers/oven_controller.dart';

class ManageOvensPage extends StatefulWidget {
  const ManageOvensPage({
    super.key,
    required this.controller,
  });

  final OvenController controller;

  @override
  State<ManageOvensPage> createState() => _ManageOvensPageState();
}

class _ManageOvensPageState extends State<ManageOvensPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  void _handleSearchChanged() {
    if (_searchQuery == _searchController.text.trim()) {
      return;
    }

    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _showAppMessage(
    String message, {
    bool isError = false,
  }) async {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : null,
      ),
    );
  }

  Future<void> _openAddOvenDialog() async {
    final TextEditingController nameController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              setLocalState(() {
                _submitting = true;
              });

              try {
                await widget.controller.addManagedOven(nameController.text);

                if (!mounted) {
                  return;
                }

                Navigator.of(context).pop();
                setState(() {});
                await _showAppMessage('Oven added successfully.');
              } catch (e) {
                setLocalState(() {
                  _submitting = false;
                });

                await _showAppMessage(
                  e.toString().replaceFirst('Exception: ', ''),
                  isError: true,
                );
              }
            }

            return AlertDialog(
              title: const Text('Add Oven'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: nameController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => submit(),
                  decoration: const InputDecoration(
                    labelText: 'Oven name',
                    hintText: 'e.g. Oven 5',
                  ),
                  validator: (value) {
                    return widget.controller.validateManagedOvenName(value ?? '');
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: _submitting ? null : submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    _submitting = false;
  }

  Future<void> _openEditOvenDialog(String currentName) async {
    final TextEditingController nameController =
        TextEditingController(text: currentName);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              setLocalState(() {
                _submitting = true;
              });

              try {
                await widget.controller.renameManagedOven(
                  oldName: currentName,
                  newName: nameController.text,
                );

                if (!mounted) {
                  return;
                }

                Navigator.of(context).pop();
                setState(() {});
                await _showAppMessage('Oven updated successfully.');
              } catch (e) {
                setLocalState(() {
                  _submitting = false;
                });

                await _showAppMessage(
                  e.toString().replaceFirst('Exception: ', ''),
                  isError: true,
                );
              }
            }

            return AlertDialog(
              title: const Text('Edit Oven'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: nameController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => submit(),
                  decoration: const InputDecoration(
                    labelText: 'Oven name',
                  ),
                  validator: (value) {
                    return widget.controller.validateManagedOvenName(
                      value ?? '',
                      excludeName: currentName,
                    );
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: _submitting ? null : submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    _submitting = false;
  }

  Future<void> _confirmDeleteOven(String ovenName) async {
    final bool isActive = widget.controller.isOvenActive(ovenName);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Oven'),
          content: Text(
            isActive
                ? 'This oven is currently active and cannot be deleted.'
                : 'Delete "$ovenName" from your oven list?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(isActive ? 'Close' : 'Cancel'),
            ),
            if (!isActive)
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await widget.controller.removeManagedOven(ovenName);

      if (!mounted) {
        return;
      }

      setState(() {});
      await _showAppMessage('Oven deleted successfully.');
    } catch (e) {
      await _showAppMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final List<String> allOvens = widget.controller.managedOvens;
        final List<String> filteredOvens = allOvens.where((oven) {
          if (_searchQuery.isEmpty) {
            return true;
          }

          return oven.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        final int totalCount = allOvens.length;
        final int activeCount = allOvens
            .where(widget.controller.isOvenActive)
            .length;
        final int availableCount = totalCount - activeCount < 0
            ? 0
            : totalCount - activeCount;

        return Scaffold(
          backgroundColor: AppColors.bg,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openAddOvenDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Add Oven',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: <Widget>[
                _PageHeader(
                  title: 'Manage Ovens',
                  subtitle: 'Add, edit, and organize the ovens used for tracking',
                  onBack: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 18),
                _HeroManageCard(
                  totalCount: totalCount,
                  activeCount: activeCount,
                  availableCount: availableCount,
                ),
                const SizedBox(height: 18),
                _SectionTitle(
                  title: 'Search',
                  subtitle: 'Quickly find a specific oven from your configured list',
                ),
                const SizedBox(height: 12),
                _SurfaceCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search ovens...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: AppColors.surfaceAlt.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _SectionTitle(
                  title: 'Oven List',
                  subtitle: filteredOvens.isEmpty
                      ? 'No ovens match your current search'
                      : '${filteredOvens.length} ovens visible',
                ),
                const SizedBox(height: 12),
                if (filteredOvens.isEmpty)
                  _EmptyStateCard(
                    title: _searchQuery.isEmpty
                        ? 'No ovens configured'
                        : 'No matching ovens',
                    subtitle: _searchQuery.isEmpty
                        ? 'Add your first oven to start using a personalized oven list.'
                        : 'Try a different name or clear the search field.',
                    buttonLabel: _searchQuery.isEmpty ? 'Add Oven' : 'Clear Search',
                    onPressed: _searchQuery.isEmpty
                        ? _openAddOvenDialog
                        : () {
                            _searchController.clear();
                          },
                  )
                else
                  ...filteredOvens.map((ovenName) {
                    final bool isActive = widget.controller.isOvenActive(ovenName);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OvenTileCard(
                        ovenName: ovenName,
                        isActive: isActive,
                        onEdit: isActive
                            ? null
                            : () => _openEditOvenDialog(ovenName),
                        onDelete: () => _confirmDeleteOven(ovenName),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _RoundIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroManageCard extends StatelessWidget {
  const _HeroManageCard({
    required this.totalCount,
    required this.activeCount,
    required this.availableCount,
  });

  final int totalCount;
  final int activeCount;
  final int availableCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF12284B),
            Color(0xFF101F39),
            Color(0xFF0B1628),
          ],
        ),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.95),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'OVEN DIRECTORY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Keep your oven list clean, clear, and easy to manage.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              _MiniStatCard(
                title: 'Total',
                value: '$totalCount',
                icon: Icons.grid_view_rounded,
              ),
              const SizedBox(width: 12),
              _MiniStatCard(
                title: 'Active',
                value: '$activeCount',
                icon: Icons.local_fire_department_rounded,
              ),
              const SizedBox(width: 12),
              _MiniStatCard(
                title: 'Available',
                value: '$availableCount',
                icon: Icons.check_circle_outline_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.card,
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _OvenTileCard extends StatelessWidget {
  const _OvenTileCard({
    required this.ovenName,
    required this.isActive,
    required this.onEdit,
    required this.onDelete,
  });

  final String ovenName;
  final bool isActive;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final Color accent = isActive ? AppColors.warning : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.card,
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.local_fire_department_rounded,
                color: accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    ovenName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isActive ? 'Currently Active' : 'Available',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _ActionIconButton(
              icon: Icons.edit_rounded,
              tooltip: isActive ? 'Cannot edit active oven' : 'Edit',
              color: AppColors.textSecondary,
              onTap: onEdit,
            ),
            const SizedBox(width: 8),
            _ActionIconButton(
              icon: Icons.delete_outline_rounded,
              tooltip: isActive ? 'Delete oven' : 'Delete',
              color: AppColors.danger,
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: onTap == null ? 0.06 : 0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              color: onTap == null
                  ? AppColors.textMuted.withValues(alpha: 0.6)
                  : color,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.card,
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.inbox_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              buttonLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}