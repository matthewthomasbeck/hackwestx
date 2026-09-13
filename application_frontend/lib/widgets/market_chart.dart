/*################################################################################*/
/* Copyright (c) 2026 Matthew Thomas Beck                                         */
/*                                                                                */
/* Licensed under the Creative Commons Attribution-NonCommercial 4.0              */
/* International (CC BY-NC 4.0). Personal and educational use is permitted.       */
/* Commercial use by companies or for-profit entities is prohibited.              */
/*################################################################################*/




/*############################################################*/
/*############### IMPORT / CREATE DEPENDENCIES ###############*/
/*############################################################*/


/*########## IMPORT DEPENDENCIES ##########*/

/*##### import necessary libraries #####*/

import 'package:flutter/material.dart'; // import Flutter painting helpers (includes dart:ui Path)

/*##### import local modules #####*/

import '../models/market.dart'; // import OHLCV / prediction points
import '../theme/app_theme.dart'; // import brand colors





/*##################################################*/
/*############### MARKET CHART #####################*/
/*##################################################*/


/*########## MARKET CHART ##########*/

class MarketChart extends StatelessWidget { // class to paint real (solid) + prediction (dashed) closes

  const MarketChart({
    super.key,
    required this.real,
    required this.predictions,
  }); // construct from market series

  final List<OhlcvPoint> real; // historical closes
  final List<PredictionPoint> predictions; // forward closes

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build chart surface

    if (real.isEmpty) { // nothing to plot
      return const Center(child: Text('No chart data yet')); // empty hint
    }

    return CustomPaint(
      painter: _MarketChartPainter(
        real: real,
        predictions: predictions,
      ),
      child: const SizedBox.expand(), // fill parent
    ); // painted chart

  }

}


/*########## MARKET CHART PAINTER ##########*/

class _MarketChartPainter extends CustomPainter { // class to draw dual-series price path

  _MarketChartPainter({
    required this.real,
    required this.predictions,
  }); // construct painter

  final List<OhlcvPoint> real; // solid history
  final List<PredictionPoint> predictions; // dashed forecast

  /*########## PAINT ##########*/

  @override
  void paint(Canvas canvas, Size size) { // function to draw real + prediction polylines

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
      ..color = AppColors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round; // solid blue history
    canvas.drawPath(realPath, realPaint); // draw history

    if (predictions.isEmpty) { // no forecast overlay
      return; // done
    }

    final predPath = Path(); // dashed forecast path
    // Bridge from last real close into first prediction for continuity
    final bridgeStart = pointAt(real.length - 1, real.last.close); // last real
    predPath.moveTo(bridgeStart.dx, bridgeStart.dy); // start at last real
    for (var i = 0; i < predictions.length; i++) { // each forecast
      final pt = pointAt(real.length + i, predictions[i].predictedClose); // mapped
      predPath.lineTo(pt.dx, pt.dy); // segment
    }

    final predPaint = Paint()
      ..color = AppColors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round; // green forecast
    _drawDashedPath(canvas, predPath, predPaint); // dashed overlay

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
  bool shouldRepaint(covariant _MarketChartPainter oldDelegate) { // function to repaint when series change

    return oldDelegate.real != real || oldDelegate.predictions != predictions; // data changed

  }

}
