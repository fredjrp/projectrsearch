import 'package:flutter/material.dart';

class SkeletonLoading extends StatefulWidget {
  const SkeletonLoading({Key? key}) : super(key: key);

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                _buildSkeletonBox(width: 200, height: 32),
                const SizedBox(height: 16),
                _buildSkeletonBox(width: double.infinity, height: 20),
                const SizedBox(height: 8),
                _buildSkeletonBox(width: 250, height: 20),
                const SizedBox(height: 48),
                _buildSkeletonBox(width: double.infinity, height: 56, borderRadius: 16),
                const SizedBox(height: 24),
                _buildSkeletonBox(width: double.infinity, height: 56, borderRadius: 16),
                const Spacer(),
                _buildSkeletonBox(width: double.infinity, height: 56, borderRadius: 28),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonBox({required double width, required double height, double borderRadius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment( _animation.value, 0),
          end: const Alignment(1, 0),
          colors: const [
            Color(0xFFEBEBEB),
            Color(0xFFF4F4F4),
            Color(0xFFEBEBEB),
          ],
          stops: const [0.1, 0.5, 0.9],
        ),
      ),
    );
  }
}
