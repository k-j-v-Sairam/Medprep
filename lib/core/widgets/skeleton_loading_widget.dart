import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

// Helper for consistent premium skeleton styling
class SkeletonContainer extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const SkeletonContainer({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 16.0,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // Base color slightly lighter than surface to make the shimmer pop
        color: context.adaptiveSurfaceHigh.withValues(alpha: 0.5),
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
        border: Border.all(
          color: context.adaptiveGlassBorder.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
    );
  }
}

class BaseSkeletonShimmer extends StatelessWidget {
  final Widget child;
  const BaseSkeletonShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.adaptiveSurfaceHigh,
      highlightColor: context.adaptiveSurfaceHighest.withValues(alpha: 0.8),
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

class SkeletonLoadingWidget extends StatelessWidget {
  const SkeletonLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseSkeletonShimmer(
      child: ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.all(20),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonContainer(
                width: 56,
                height: 56,
                shape: BoxShape.circle,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonContainer(
                      width: double.infinity,
                      height: 18,
                      borderRadius: 6,
                    ),
                    const SizedBox(height: 10),
                    const SkeletonContainer(
                      width: 160,
                      height: 14,
                      borderRadius: 6,
                    ),
                    const SizedBox(height: 16),
                    const SkeletonContainer(
                      width: double.infinity,
                      height: 60,
                      borderRadius: 12,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class SyllabusSkeletonWidget extends StatelessWidget {
  const SyllabusSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseSkeletonShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        itemCount: 6,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: SkeletonContainer(
            height: 140, // Match approx height of _SubjectCard
            borderRadius: 20,
          ),
        ),
      ),
    );
  }
}

class TopicListSkeletonWidget extends StatelessWidget {
  const TopicListSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseSkeletonShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: SkeletonContainer(
            height: 160,
            borderRadius: 20,
          ),
        ),
      ),
    );
  }
}

class ArenaSkeletonWidget extends StatelessWidget {
  const ArenaSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseSkeletonShimmer(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          SkeletonContainer(height: 140, borderRadius: 20),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: SkeletonContainer(height: 120, borderRadius: 20)),
              SizedBox(width: 16),
              Expanded(child: SkeletonContainer(height: 120, borderRadius: 20)),
            ],
          ),
          SizedBox(height: 20),
          SkeletonContainer(height: 200, borderRadius: 20),
        ],
      ),
    );
  }
}

class MasterySkeletonWidget extends StatelessWidget {
  const MasterySkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseSkeletonShimmer(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          SkeletonContainer(height: 120, borderRadius: 20),
          SizedBox(height: 20),
          SkeletonContainer(height: 240, borderRadius: 24),
          SizedBox(height: 20),
          SkeletonContainer(height: 80, borderRadius: 16),
          SizedBox(height: 12),
          SkeletonContainer(height: 80, borderRadius: 16),
        ],
      ),
    );
  }
}

class CardBrowserSkeletonWidget extends StatelessWidget {
  const CardBrowserSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseSkeletonShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: 12,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12.0),
          child: SkeletonContainer(
            height: 72,
            borderRadius: 16,
          ),
        ),
      ),
    );
  }
}
