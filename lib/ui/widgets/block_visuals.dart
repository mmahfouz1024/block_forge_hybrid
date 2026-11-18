import 'package:flutter/material.dart';
import '../../models/game_models.dart';

class GlossBlockTile extends StatelessWidget {
  final BlockColor color;
  final double size;
  final int iceHits;
  final bool hasGem;
  final bool isGhost;
  final bool isHighlightClear;

  const GlossBlockTile({
    super.key,
    required this.color,
    required this.size,
    this.iceHits = 0,
    this.hasGem = false,
    this.isGhost = false,
    this.isHighlightClear = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isHighlightClear
        ? const Color(0xFFFDE047)
        : (isGhost ? color.base.withValues(alpha: 0.48) : color.base);
    final hiColor = isHighlightClear
        ? Colors.white.withValues(alpha: 0.7)
        : (isGhost ? color.highlight.withValues(alpha: 0.35) : color.highlight);
    final loColor = isHighlightClear
        ? const Color(0xFFD97706)
        : (isGhost ? color.shadow.withValues(alpha: 0.4) : color.shadow);

    final radius = (size * 0.22).clamp(3.0, 10.0);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: iceHits > 0
              ? const Color(0xFFE0F2FE)
              : (isHighlightClear ? Colors.white : loColor.withValues(alpha: 0.7)),
          width: iceHits > 0 ? 2.0 : 1.0,
        ),
        boxShadow: isGhost
            ? null
            : [
                BoxShadow(
                  color: loColor.withValues(alpha: 0.55),
                  offset: const Offset(0, 2),
                  blurRadius: 2,
                ),
              ],
      ),
      child: Stack(
        children: [
          // Top specular shine
          Positioned(
            left: size * 0.12,
            right: size * 0.12,
            top: size * 0.09,
            height: size * 0.3,
            child: Container(
              decoration: BoxDecoration(
                color: hiColor.withValues(alpha: isGhost ? 0.25 : 0.45),
                borderRadius: BorderRadius.circular(radius * 0.6),
              ),
            ),
          ),
          if (iceHits > 0)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Center(
                  child: Icon(
                    iceHits >= 2 ? Icons.ac_unit : Icons.grain,
                    size: size * 0.54,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ),
          if (hasGem)
            Center(
              child: Container(
                width: size * 0.52,
                height: size * 0.52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F172A).withValues(alpha: 0.45),
                ),
                child: Icon(
                  Icons.diamond,
                  size: size * 0.38,
                  color: const Color(0xFFFEF08A),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ShapePreviewWidget extends StatelessWidget {
  final BlockShape shape;
  final double cellSize;
  final double spacing;
  final double opacity;

  const ShapePreviewWidget({
    super.key,
    required this.shape,
    required this.cellSize,
    this.spacing = 2.5,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Opacity(
        opacity: opacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(shape.rows, (r) {
            return Padding(
              padding: EdgeInsets.only(bottom: r == shape.rows - 1 ? 0 : spacing),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(shape.cols, (c) {
                  final filled = shape.matrix[r][c] == 1;
                  return Padding(
                    padding: EdgeInsets.only(right: c == shape.cols - 1 ? 0 : spacing),
                    child: filled
                        ? GlossBlockTile(color: shape.color, size: cellSize)
                        : SizedBox(width: cellSize, height: cellSize),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}
