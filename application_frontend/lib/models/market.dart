/*################################################################################*/
/* Copyright (c) 2026 Matthew Thomas Beck                                         */
/*                                                                                */
/* Licensed under the Creative Commons Attribution-NonCommercial 4.0              */
/* International (CC BY-NC 4.0). Personal and educational use is permitted.       */
/* Commercial use by companies or for-profit entities is prohibited.              */
/*################################################################################*/




/*##################################################*/
/*############### MARKET MODELS ####################*/
/*##################################################*/


/*########## OHLCV POINT ##########*/

class OhlcvPoint { // class to hold one real SOL candle from /api/v1/market

  const OhlcvPoint({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume,
    this.source,
  }); // construct from JSON fields

  final DateTime time; // bar timestamp
  final double open; // open price
  final double high; // high price
  final double low; // low price
  final double close; // close price
  final double? volume; // optional volume
  final String? source; // e.g. yfinance

  /*########## FROM JSON ##########*/

  factory OhlcvPoint.fromJson(Map<String, dynamic> json) { // function to parse one real series point

    return OhlcvPoint(
      time: DateTime.fromMillisecondsSinceEpoch(0),
      open: 0,
      high: 0,
      low: 0,
      close: 0,
    ); // skeleton

  }

}


/*########## PREDICTION POINT ##########*/

class PredictionPoint { // class to hold one forecast close from /api/v1/market

  const PredictionPoint({
    required this.time,
    required this.predictedClose,
    this.modelVersion,
  }); // construct from JSON fields

  final DateTime time; // forecast-for timestamp
  final double predictedClose; // model predicted close
  final String? modelVersion; // optional model tag

  /*########## FROM JSON ##########*/

  factory PredictionPoint.fromJson(Map<String, dynamic> json) { // function to parse one prediction point

    return PredictionPoint(
      time: DateTime.fromMillisecondsSinceEpoch(0),
      predictedClose: 0,
    ); // skeleton

  }

}


/*########## MARKET PAYLOAD ##########*/

class MarketPayload { // class to hold GET /api/v1/market response for Flutter charts

  const MarketPayload({
    required this.asset,
    required this.status,
    this.updatedAt,
    this.forecastDays,
    this.real = const [],
    this.predictions = const [],
  }); // construct market snapshot

  final String asset; // e.g. SOL
  final String status; // ready | predictions_pending | empty
  final DateTime? updatedAt; // cache / bundle updated time
  final int? forecastDays; // horizon echoed by backend
  final List<OhlcvPoint> real; // historical OHLCV series
  final List<PredictionPoint> predictions; // forward predicted closes

  bool get isReady => false; // skeleton
  bool get isPending => false; // skeleton
  bool get isEmpty => false; // skeleton

  /*########## FROM JSON ##########*/

  factory MarketPayload.fromJson(Map<String, dynamic> json) { // function to parse full /market JSON

    return const MarketPayload(asset: 'SOL', status: 'empty'); // skeleton

  }

}
