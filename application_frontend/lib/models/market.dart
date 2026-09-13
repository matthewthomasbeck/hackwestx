/*##################################################*/
/*############### MARKET MODELS ####################*/
/*##################################################*/


/*########## OHLCV POINT ##########*/

class OhlcvPoint { // class to hold one real SOL candle from /api/v1/market real.series

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
      time: DateTime.parse(json['time'] as String), // ISO time from backend
      open: (json['open'] as num).toDouble(), // open
      high: (json['high'] as num).toDouble(), // high
      low: (json['low'] as num).toDouble(), // low
      close: (json['close'] as num).toDouble(), // close
      volume: json['volume'] == null ? null : (json['volume'] as num).toDouble(), // optional volume
      source: json['source'] as String?, // optional source tag
    ); // parsed candle

  }

}


/*########## PREDICTION POINT ##########*/

class PredictionPoint { // class to hold one forecast close from /api/v1/market predictions.series

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
      time: DateTime.parse(json['time'] as String), // ISO time from backend
      predictedClose: (json['predicted_close'] as num).toDouble(), // predicted close
      modelVersion: json['model_version'] as String?, // optional version
    ); // parsed forecast point

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

  bool get isReady => status == 'ready'; // True when real + predictions usable
  bool get isPending => status == 'predictions_pending'; // True while LSTM runs
  bool get isEmpty => status == 'empty'; // True when no Tiger data yet

  /*########## FROM JSON ##########*/

  factory MarketPayload.fromJson(Map<String, dynamic> json) { // function to parse full /market JSON

    final realRaw = (json['real'] as Map<String, dynamic>?)?['series'] as List<dynamic>? ?? []; // real bars
    final predRaw = (json['predictions'] as Map<String, dynamic>?)?['series'] as List<dynamic>? ?? []; // forecasts

    return MarketPayload(
      asset: json['asset'] as String? ?? 'SOL', // default SOL
      status: json['status'] as String? ?? 'empty', // default empty
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'] as String), // optional updated_at
      forecastDays: json['forecast_days'] as int?, // optional horizon
      real: realRaw
          .map((e) => OhlcvPoint.fromJson(e as Map<String, dynamic>))
          .toList(), // parse candles
      predictions: predRaw
          .map((e) => PredictionPoint.fromJson(e as Map<String, dynamic>))
          .toList(), // parse forecasts
    ); // parsed market payload

  }

}
