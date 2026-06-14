import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../../core/theme/panel_theme.dart';
import '../../models/location_data.dart';
import '../../providers/explore_provider.dart';

class SearchLocationBar extends ConsumerStatefulWidget {
  const SearchLocationBar({super.key, this.onLocationSelected});

  final void Function(SelectedLocation)? onLocationSelected;

  @override
  ConsumerState<SearchLocationBar> createState() => _SearchLocationBarState();
}

class _SearchLocationBarState extends ConsumerState<SearchLocationBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<SelectedLocation> _results = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.trim().length < 2) {
        setState(() => _results = []);
        return;
      }
      setState(() => _isSearching = true);
      try {
        final results = await ref.read(exploreProvider.notifier).searchPlaces(query);
        if (mounted) setState(() => _results = results);
      } catch (_) {}
      if (mounted) setState(() => _isSearching = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: PanelColors.searchBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: font(
              color: PanelColors.textPrimary,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: l10n.searchLocation,
              hintStyle: font(
                color: PanelColors.textMuted,
                fontSize: 13,
              ),
              prefixIcon: const Icon(Icons.search, color: PanelColors.textMuted, size: 18),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: PanelColors.accent,
                        ),
                      ),
                    )
                  : _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: PanelColors.textMuted, size: 16),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _results = []);
                          },
                        )
                      : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: _onChanged,
          ),
        ),
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: PanelColors.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: PanelColors.cardBorder),
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _results.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                color: PanelColors.divider,
              ),
              itemBuilder: (context, index) {
                final loc = _results[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    loc.displayName,
                    style: font(
                      color: PanelColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    loc.subtitle,
                    style: font(
                      color: PanelColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  onTap: () {
                    _controller.text = loc.displayName;
                    setState(() => _results = []);
                    _focusNode.unfocus();
                    widget.onLocationSelected?.call(loc);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
