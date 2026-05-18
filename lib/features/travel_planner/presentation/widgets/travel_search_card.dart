import 'dart:ui';

import 'package:fin_track/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TravelSearchCard extends StatefulWidget {
  final TextEditingController controller;
  final String? selectedDestination;
  final List<String> suggestions;
  final ValueChanged<String> onSearch;

  const TravelSearchCard({
    super.key,
    required this.controller,
    required this.selectedDestination,
    required this.suggestions,
    required this.onSearch,
  });

  @override
  State<TravelSearchCard> createState() => _TravelSearchCardState();
}

class _TravelSearchCardState extends State<TravelSearchCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isFocused
              ? context.colors.primary
              : context.colors.border,
          width: _isFocused ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withValues(alpha: _isFocused ? 0.12 : 0.04),
            blurRadius: _isFocused ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: context.colors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CARI DESTINASI',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4,
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Field
                Focus(
                  onFocusChange: (v) => setState(() => _isFocused = v),
                  child: TextField(
                    controller: widget.controller,
                    textInputAction: TextInputAction.search,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Kota, pantai, gunung...',
                      hintStyle: GoogleFonts.outfit(
                        color: context.colors.textMuted,
                        fontSize: 14,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.search_rounded,
                          color: context.colors.textMuted,
                          size: 20,
                        ),
                      ),
                      suffixIcon: _SearchButton(
                        onTap: () => widget.onSearch(widget.controller.text),
                      ),
                      filled: true,
                      fillColor: context.colors.backgroundSecondary.withValues(alpha: 0.7),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: widget.onSearch,
                  ),
                ),

                const SizedBox(height: 14),

                // Quick suggestions
                Text(
                  'Populer',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: context.colors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.suggestions.map((destination) {
                    final selected = destination == widget.selectedDestination;
                    return _DestinationChip(
                      label: destination,
                      isSelected: selected,
                      onTap: () {
                        widget.controller.text = destination;
                        widget.onSearch(destination);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: context.colors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _DestinationChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DestinationChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primary.withValues(alpha: 0.15)
              : context.colors.backgroundSecondary,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? context.colors.primary
                : context.colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check_circle_rounded,
                size: 13,
                color: context.colors.primary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? context.colors.primaryDark
                    : context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
