/*############################################################*/
/*############### IMPORT / CREATE DEPENDENCIES ###############*/
/*############################################################*/


/*########## IMPORT DEPENDENCIES ##########*/

/*##### import necessary libraries #####*/

import 'package:flutter/material.dart'; // import Flutter painting helpers (includes dart:ui Path)

/*##### import local modules #####*/

import '../models/market.dart'; // import OHLCV / prediction points
import '../theme/app_theme.dart'; // import Solana gradient





/*##################################################*/
/*############### MARKET CHART #####################*/
/*##################################################*/


/*########## MARKET CHART ##########*/

class MarketChart extends StatefulWidget { // class to paint real + dashed forecast with pinging dots

  const MarketChart({
    super.key,
    required this.real,
    required this.predictions,
  }); // construct from market series

  final List<OhlcvPoint> real; // historical closes
  final List<PredictionPoint> predictions; // forward closes

  @override
  State<MarketChart> createState() => _MarketChartState(); // create animated state

}


/*########## MARKET CHART STATE ##########*/

class _MarketChartState extends State<MarketChart>
    with SingleTickerProviderStateMixin { // class to drive prediction-dot ping loop

  late final AnimationController _ping; // 0..1 ping phase

  /*########## INIT STATE ##########*/

  @override
  void initState() { // function to start repeating ping animation

    super.initState(); // Flutter init
    _ping = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(); // slower continuous soft ping

  }

  /*########## DISPOSE ##########*/

  @override
  void dispose() { // function to stop ping controller

    _ping.dispose(); // free ticker
    super.dispose(); // Flutter dispose

  }

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build animated chart surface

    if (widget.real.isEmpty) { // nothing to plot
      return const Center(child: Text('No chart data yet')); // empty hint
    }

    return AnimatedBuilder(
      animation: _ping,
      builder: (context, _) {
        return CustomPaint(
          painter: _MarketChartPainter(
            real: widget.real,
            predictions: widget.predictions,
            pingT: _ping.value,
          ),
          child: const SizedBox.expand(), // fill parent
        ); // painted chart
      },
    );

  }

}


/*########## MARKET CHART PAINTER ##########*/

class _MarketChartPainter extends CustomPainter { // class to draw gradient real + forecast + dots

  _MarketChartPainter({
    required this.real,
    required this.predictions,
    required this.pingT,
  }); // construct painter

  final List<OhlcvPoint> real; // solid history
  final List<PredictionPoint> predictions; // dashed forecast
  final double pingT; // 0..1 ping animation phase

  /*########## PAINT ##########*/

  @override
  void paint(Canvas canvas, Size size) { // function to draw gradient polylines + dots

    final realYs = real.map((p) => p.close).toList(); // history closes
    final predYs = predictions.map((p) => p.predictedClose).toList(); // forecast closes
    final allYs = [...realYs, ...predYs]; // scale domain
    var minY = allYs.reduce((a, b) => a < b ? a : b); // min price
    var maxY = allYs.reduce((a, b) => a > b ? a : b); // max price
    if ((maxY - minY).abs() < 1e-9) { // flat series
      minY -= 1; // pad
      maxY += 1; // pad
    }
    final pad = (maxY - minY) * 0.08; // vertical breathing room
    minY -= pad; // expand
    maxY += pad; // expand

    final totalPoints = real.length + predictions.length; // x span
    final dx = totalPoints <= 1 ? size.width : size.width / (totalPoints - 1); // step
    final shader = AppColors.solanaDiagonal.createShader(Offset.zero & size); // shared Solana stroke fill

    double yFor(double price) { // map price → canvas y
      final t = (price - minY) / (maxY - minY); // 0..1
      return size.height - (t * size.height); // flip y
    }

    Offset pointAt(int index, double price) { // map index/price → canvas point
      return Offset(index * dx, yFor(price)); // chart point
    }

    final realPath = Path(); // solid history path
    for (var i = 0; i < real.length; i++) { // each candle
      final pt = pointAt(i, real[i].close); // mapped
      if (i == 0) { // start
        realPath.moveTo(pt.dx, pt.dy); // begin
      } else {
        realPath.lineTo(pt.dx, pt.dy); // segment
      }
    }

    final realPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round; // gradient real history
    canvas.drawPath(realPath, realPaint); // draw history

    if (predictions.isEmpty) { // no forecast overlay
      return; // done
    }

    final predPath = Path(); // dashed forecast path
    final bridgeStart = pointAt(real.length - 1, real.last.close); // last real
    predPath.moveTo(bridgeStart.dx, bridgeStart.dy); // start at last real
    for (var i = 0; i < predictions.length; i++) { // each forecast
      final pt = pointAt(real.length + i, predictions[i].predictedClose); // mapped
      predPath.lineTo(pt.dx, pt.dy); // segment
    }

    final predPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round; // gradient forecast
    _drawDashedPath(canvas, predPath, predPaint); // dashed overlay

    for (var i = 0; i < predictions.length; i++) { // pinging markers on forecast points
      final pt = pointAt(real.length + i, predictions[i].predictedClose); // marker center
      _drawPingingDot(canvas, pt, i, shader); // gradient core + ping
    }

  }

  /*########## DRAW PINGING DOT ##########*/

  void _drawPingingDot(Canvas canvas, Offset center, int index, Shader shader) { // function to draw gradient core + soft ping

    const coreRadius = 3.6; // solid marker size
    final corePaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.fill; // gradient core
    canvas.drawCircle(center, coreRadius, corePaint); // prediction dot

    final localT = (pingT + index * 0.18) % 1.0; // phase offset per point
    final eased = Curves.easeOut.transform(localT); // expand then fade
    final ringRadius = coreRadius + eased * 18.0; // growing filled circle
    final ringPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.fill;
    canvas.saveLayer(
      Rect.fromCircle(center: center, radius: ringRadius + 2),
      Paint()..color = Color.fromRGBO(255, 255, 255, (1.0 - eased) * 0.80),
    ); // twice-as-strong fade ping as it expands
    canvas.drawCircle(center, ringRadius, ringPaint); // translucent expanding ping
    canvas.restore();
    canvas.drawCircle(center, coreRadius, corePaint); // keep core crisp on top

  }

  /*########## DRAW DASHED PATH ##########*/

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) { // function to stroke a path as dashes

    const dashWidth = 8.0; // dash length
    const dashSpace = 5.0; // gap length
    for (final metric in path.computeMetrics()) { // each contour
      var distance = 0.0; // walk along path
      while (distance < metric.length) { // remaining length
        final next = distance + dashWidth; // dash end
        final extract = metric.extractPath(distance, next.clamp(0, metric.length)); // dash segment
        canvas.drawPath(extract, paint); // draw dash
        distance = next + dashSpace; // skip gap
      }
    }

  }

  /*########## SHOULD REPAINT ##########*/

  @override
  bool shouldRepaint(covariant _MarketChartPainter oldDelegate) { // function to repaint when series/ping change

    return oldDelegate.real != real ||
        oldDelegate.predictions != predictions ||
        oldDelegate.pingT != pingT; // data or ping frame changed

  }

}
