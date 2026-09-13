/*############################################################*/
/*############### IMPORT / CREATE DEPENDENCIES ###############*/
/*############################################################*/


/*########## IMPORT DEPENDENCIES ##########*/

/*##### import necessary libraries #####*/

import 'dart:convert'; // import JSON encode/decode helpers

/*##### import third-party libraries #####*/

import 'package:http/http.dart' as http; // import HTTP client for EC2 backend

/*##### import local modules #####*/

import '../config.dart'; // import API base URL
import '../models/market.dart'; // import MarketPayload parsers





/*##################################################*/
/*############### API SERVICE ######################*/
/*##################################################*/


/*########## API SERVICE ##########*/

class ApiService { // class to call application_backend market / identity endpoints

  ApiService({
    http.Client? client,
    String? baseUrl,
    this.accessToken,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? AppConfig.apiBaseUrl; // allow inject client / base for tests

  final http.Client _client; // shared HTTP client
  final String baseUrl; // EC2 application_backend origin
  String? accessToken; // Auth0 Bearer token from login

  static const _timeout = Duration(seconds: 15); // request timeout

  /*########## URI ##########*/

  Uri _uri(String path) { // function to join base URL + path into a Uri

    return Uri.parse('$baseUrl$path'); // absolute URI

  }

  /*########## AUTH HEADERS ##########*/

  Map<String, String> _headers() { // function to build JSON + optional Bearer headers

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    }; // base headers
    final token = accessToken; // current token snapshot
    if (token != null && token.isNotEmpty) { // Auth0 session present
      headers['Authorization'] = 'Bearer $token'; // attach user JWT
    }
    return headers; // request headers

  }

  /*########## GET ME ##########*/

  Future<Map<String, dynamic>> getMe() async { // function to GET /api/v1/me for Auth0 identity

    final response = await _client
        .get(_uri('/api/v1/me'), headers: _headers())
        .timeout(_timeout); // identity request
    if (response.statusCode < 200 || response.statusCode >= 300) { // non-2xx
      throw Exception('GET /me failed: ${response.statusCode} ${response.body}'); // surface error
    }
    return jsonDecode(response.body) as Map<String, dynamic>; // claims payload

  }

  /*########## GET MARKET ##########*/

  Future<MarketPayload> getMarket() async { // function to GET /api/v1/market for chart JSON

    final response = await _client
        .get(_uri('/api/v1/market'), headers: _headers())
        .timeout(_timeout); // market request
    if (response.statusCode < 200 || response.statusCode >= 300) { // non-2xx
      throw Exception('GET /market failed: ${response.statusCode} ${response.body}'); // surface error
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>; // decode body
    return MarketPayload.fromJson(json); // typed market snapshot

  }

  /*########## REFRESH MARKET ##########*/

  Future<Map<String, dynamic>> refreshMarket({bool force = false}) async { // function to POST /api/v1/market/refresh (async pipeline)

    final response = await _client
        .post(
          _uri('/api/v1/market/refresh'),
          headers: _headers(),
          body: jsonEncode({
            'force': force,
            'forecast_days': 5, // always request full 5-day horizon
          }),
        )
        .timeout(_timeout); // kicks off background yfinance → Tiger → predictor
    // 202 = started, 409 = already running — both mean Flutter should poll GET /market
    if (response.statusCode != 202 &&
        response.statusCode != 409 &&
        (response.statusCode < 200 || response.statusCode >= 300)) { // unexpected failure
      throw Exception('POST /market/refresh failed: ${response.statusCode} ${response.body}'); // surface error
    }
    return jsonDecode(response.body) as Map<String, dynamic>; // started / busy summary

  }

  /*########## DISPOSE ##########*/

  void dispose() { // function to close the underlying HTTP client

    _client.close(); // free client resources

  }

}
