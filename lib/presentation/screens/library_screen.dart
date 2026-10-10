import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/recording_meta.dart';
import '../../providers/recordings_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import 'analysis_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  IconData _iconFor(String label) {
    final l = label.toLowerCase();
    if (l.contains('table')) return Icons.table_restaurant_rounded;
    if (l.contains('truck')) return Icons.local_shipping_rounded;
    if (l.contains('drop')) return Icons.south_rounded;
    if (l.contains('tap')) return Icons.touch_app_rounded;
    if (l.contains('shake')) return Icons.vibration_rounded;
    if (l.contains('walk')) return Icons.directions_walk_rounded;
    if (l.contains('bed')) return Icons.bed_rounded;
    return Icons.graphic_eq_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RecordingsProvider>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text('Library',
                      style: Theme.of(context).textTheme.headlineSmall),
                ),
                IconButton(
                  onPressed: p.refresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Tap a recording to replay it through the detector.',
              style: TextStyle(color: AppColors.textDim),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: p.loading && p.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : p.items.isEmpty
                    ? const EmptyState(
                        icon: Icons.folder_open_rounded,
                        title: 'No recordings yet',
                        message:
                            'Record some data on the Record tab and it will show up here.',
                      )
                    : RefreshIndicator(
                        onRefresh: p.refresh,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: p.items.length,
                          itemBuilder: (context, i) {
                            final meta = p.items[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _RecordingTile(
                                meta: meta,
                                icon: _iconFor(meta.label),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _RecordingTile extends StatelessWidget {
  const _RecordingTile({required this.meta, required this.icon});

  final RecordingMeta meta;
  final IconData icon;

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AnalysisScreen(meta: meta)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => _open(context),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meta.label,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${formatDuration(meta.durationMs)} · ${meta.rateHz.toStringAsFixed(0)} Hz · ${formatDateTime(meta.created)}',
                  style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                ),
                if (meta.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(meta.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textDim, fontSize: 12)),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: AppColors.surfaceHigh,
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textDim),
            onSelected: (v) async {
              if (v == 'analyze') {
                _open(context);
              } else if (v == 'share') {
                await Share.shareXFiles([XFile(meta.path)],
                    text: 'Quake Watch recording: ${meta.label}');
              } else if (v == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surfaceHigh,
                    title: const Text('Delete recording?'),
                    content: Text('${meta.label} will be removed permanently.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete',
                              style: TextStyle(color: AppColors.danger))),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await context.read<RecordingsProvider>().delete(meta);
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'analyze', child: Text('Analyze')),
              PopupMenuItem(value: 'share', child: Text('Share CSV')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
