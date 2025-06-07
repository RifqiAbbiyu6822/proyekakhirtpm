import 'package:flutter/material.dart';
import '../theme/theme.dart';

class LifeIndicator extends StatefulWidget {
  final int lives;

  const LifeIndicator({Key? key, required this.lives}) : super(key: key);

  @override
  State<LifeIndicator> createState() => LifeIndicatorState();
}

class LifeIndicatorState extends State<LifeIndicator> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _beatAnimations;
  static const int maxLives = 5;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(maxLives, (index) =>
      AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      )
    );

    _scaleAnimations = _controllers.map((controller) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
        ),
      )
    ).toList();

    _beatAnimations = _controllers.map((controller) =>
      Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.6, 1.0, curve: Curves.elasticInOut),
        ),
      )
    ).toList();

    // Start animations for current lives with sequential delay
    for (int i = 0; i < (widget.lives.clamp(0, maxLives)); i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].forward();
          // Start continuous beating animation
          _startBeatingAnimation(i);
        }
      });
    }
  }

  void _startBeatingAnimation(int index) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && index < widget.lives) {
        _controllers[index].repeat(
          reverse: true,
          period: const Duration(milliseconds: 1000),
        );
      }
    });
  }

  @override
  void didUpdateWidget(LifeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldLives = oldWidget.lives.clamp(0, maxLives);
    final newLives = widget.lives.clamp(0, maxLives);

    if (newLives < oldLives) {
      // Animate life loss
      for (int i = newLives; i < oldLives; i++) {
        _controllers[i].stop();
        _controllers[i].reverse();
      }
    } else if (newLives > oldLives) {
      // Animate life gain
      for (int i = oldLives; i < newLives; i++) {
        _controllers[i].reset();
        _controllers[i].forward().then((_) {
          _startBeatingAnimation(i);
        });
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Lives text indicator
          Text(
            'Lives Remaining',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: DynamicAppTheme.lifeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Hearts row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(maxLives, (index) {
              bool isActive = index < widget.lives;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ScaleTransition(
                  scale: _scaleAnimations[index],
                  child: ScaleTransition(
                    scale: _beatAnimations[index],
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive 
                            ? DynamicAppTheme.lifeColor.withAlpha(25)
                            : Colors.grey[300]?.withAlpha(50),
                        border: Border.all(
                          color: isActive 
                              ? DynamicAppTheme.lifeColor 
                              : Colors.grey[400] ?? Colors.grey,
                          width: 2,
                        ),
                        boxShadow: isActive ? [
                          BoxShadow(
                            color: DynamicAppTheme.lifeColor.withAlpha(60),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: DynamicAppTheme.lifeColor.withAlpha(30),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Icon(
                        isActive ? Icons.favorite : Icons.favorite_border,
                        color: isActive 
                            ? DynamicAppTheme.lifeColor 
                            : Colors.grey[400],
                        size: 26,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Numeric indicator
          Text(
            '${widget.lives}/$maxLives',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: DynamicAppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
