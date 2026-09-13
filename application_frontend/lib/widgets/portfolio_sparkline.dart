/*############################################################*/
/*############### IMPORT / CREATE DEPENDENCIES ###############*/
/*############################################################*/


/*########## IMPORT DEPENDENCIES ##########*/

/*##### import necessary libraries #####*/

import 'package:flutter/material.dart'; // import Flutter painting helpers

/*##### import local modules #####*/

import '../theme/app_theme.dart'; // import P&L + Solana colors





/*##################################################*/
/*############### PORTFOLIO SPARKLINE ##############*/
/*##################################################*/


/*########## PORTFOLIO SPARKLINE ##########*/

class PortfolioSparkline extends StatelessWidget { // class for mini equity-curve chart

  const PortfolioSparkline({
    super.key,
    required this.values,
  }); // construct from value series

  final List<double> values; // portfolio USD over time (oldest → newest)

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build sparkline container

    final up = values.isEmpty || values.last >= values.first; // green if flat/up
    final lineColor = up ? AppColors.green : AppColors.red; // P&L stroke

    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      child: values.isEmpty
          ? Center(
              child: Text(
                'No value history yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          : CustomPaint(
              painter: _SparklinePainter(
                values: values,
                lineColor: lineColor,
                fillColor: lineColor.withValues(alpha: 0.14),
              ),
              child: const SizedBox.expand(),
            ),
    ); // rounded mini chart

  }

}


/*########## SPARKLINE PAINTER ##########*/

class _SparklinePainter extends CustomPainter { // class to paint equity path + soft fill

  _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
  }); // construct painter

  final List<double> values; // series
  final Color lineColor; // stroke
  final Color fillColor; // under-curve wash

  /*########## PAINT ##########*/

  @override
  void paint(Canvas canvas, Size size) { // function to draw sparkline into chart box

    if (values.isEmpty || size.width <= 0 || size.height <= 0) { // nothing to draw
      return; // bail
    }

    final minV = values.reduce((a, b) => a < b ? a : b); // series low
    final maxV = values.reduce((a, b) => a > b ? a : b); // series high
    var span = maxV - minV; // vertical range
    if (span < 1e-6) { // flat series
      span = 1; // avoid divide-by-zero; center the line
    }

    const padY = 16.0; // top/bottom inset
    const padX = 12.0; // side inset
    final chartW = size.width - (padX * 2); // drawable width
    final chartH = size.height - (padY * 2); // drawable height
    final n = values.length; // point count

    Offset pointAt(int i) { // map series index → canvas point
      final x = padX + (n == 1 ? chartW / 2 : (chartW * i / (n - 1))); // evenly spaced
      final norm = (values[i] - minV) / span; // 0..1 within range
      final y = padY + chartH * (1 - norm); // invert y for canvas
      return Offset(x, y); // plotted point
    }

    final path = Path(); // stroke path
    final first = pointAt(0); // start
    path.moveTo(first.dx, first.dy); // begin
    for (var i = 1; i < n; i++) { // remaining points
      final p = pointAt(i); // next
      path.lineTo(p.dx, p.dy); // segment
    }

    final fill = Path.from(path); // under-curve area
    final last = pointAt(n - 1); // tip
    fill.lineTo(last.dx, size.height - padY); // down to baseline
    fill.lineTo(first.dx, size.height - padY); // across
    fill.close(); // seal

    canvas.drawPath(
      fill,
      Paint()
        ..style = PaintingStyle.fill
        ..color = fillColor,
    ); // soft fill

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = lineColor,
    ); // equity stroke

    canvas.drawCircle(
      last,
      4,
      Paint()..color = lineColor,
    ); // tip dot

  }

  /*########## SHOULD REPAINT ##########*/

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) { // function to skip redundant paints

    return oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        !listEquals(oldDelegate.values, values); // series or colors changed

  }

}

/*########## LIST EQUALS ##########*/

bool listEquals(List<double> a, List<double> b) { // function to compare sparkline series

  if (identical(a, b)) { // same instance
    return true; // equal
  }
  if (a.length != b.length) { // different length
    return false; // unequal
  }
  for (var i = 0; i < a.length; i++) { // pairwise
    if (a[i] != b[i]) { // mismatch
      return false; // unequal
    }
  }
  return true; // equal

}
