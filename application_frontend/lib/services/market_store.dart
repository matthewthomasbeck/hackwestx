/*############################################################*/
/*############### IMPORT / CREATE DEPENDENCIES ###############*/
/*############################################################*/


/*########## IMPORT DEPENDENCIES ##########*/

/*##### import necessary libraries #####*/

import 'dart:async'; // import Timer for pending-prediction polling

/*##### import third-party libraries #####*/

import 'package:flutter/foundation.dart'; // import ChangeNotifier for UI rebuilds

/*##### import local modules #####*/

import '../models/market.dart'; // import MarketPayload
import 'api_service.dart'; // import EC2 HTTP client





/*##################################################*/
/*############### MARKET STORE #####################*/
/*##################################################*/


/*########## MARKET STORE ##########*/

class MarketStore extends ChangeNotifier { // class to hold latest /market JSON and drive UI updates

  MarketStore(this._api); // inject shared ApiService

  final ApiService _api; // EC2 client (Bearer set via syncApiAccessToken)

  MarketPayload? market; // last successful snapshot
  String? error; // last load / refresh failure
  bool loading = false; // True during an active fetch
  bool refreshing = false; // True while POST /refresh + poll loop runs

  Timer? _pollTimer; // periodic GET while predictions_pending
  int _pollTicks = 0; // safety cap for pending polls

  static const _pollInterval = Duration(seconds: 3); // how often to re-GET while pending
  static const _maxPollTicks = 120; // ~6 minutes waiting on GPU predictor

  /*########## LAST CLOSE ##########*/

  double? get lastClose { // function to return most recent real SOL close, if any

    final series = market?.real; // OHLCV bars
    if (series == null || series.isEmpty) { // no candles
      return null; // unknown price
    }
    return series.last.close; // latest bar close

  }

  /*########## PERCENT CHANGE ##########*/

  double? get percentChange { // function to return last bar vs prior close % change

    final series = market?.real; // OHLCV bars
    if (series == null || series.length < 2) { // need two closes
      return null; // unknown
    }
    final prev = series[series.length - 2].close; // prior close
    final curr = series.last.close; // latest close
    if (prev == 0) { // avoid divide-by-zero
      return null; // unknown
    }
    return ((curr - prev) / prev) * 100.0; // percent change

  }

  /*########## LOAD ##########*/

  Future<MarketPayload> load({bool silent = false}) async { // function to GET /api/v1/market into store

    if (!silent) { // show spinner for cold loads
      loading = true; // mark busy
      error = null; // clear prior error
      notifyListeners(); // rebuild listeners
    }
    try {
      final payload = await _api.getMarket(); // Auth0-protected market JSON
      market = payload; // keep snapshot
      error = null; // success
      _syncPolling(payload); // start/stop pending poller
      return payload; // caller may branch on status
    } catch (e) {
      error = e.toString(); // surface for error page
      rethrow; // let loading/home handle routing
    } finally {
      if (!silent) { // only clear cold-load flag
        loading = false; // done
      }
      notifyListeners(); // rebuild with new state
    }

  }

  /*########## REFRESH ##########*/

  Future<void> refresh({bool force = false}) async { // function to POST /refresh then poll until ready

    refreshing = true; // mark refresh in flight
    error = null; // clear prior error
    notifyListeners(); // show pending UI
    try {
      await _api.refreshMarket(force: force); // 202 started / 409 busy
      await load(silent: true); // first snapshot after kickoff
      // Keep polling through empty → pending → ready while background pipeline runs
      if (market?.isReady != true) { // not finished yet
        _startPolling(); // GET until predictions land (or timeout)
      }
    } catch (e) {
      error = e.toString(); // network / auth failure
      rethrow; // let UI show retry
    } finally {
      refreshing = false; // POST returned; poll may continue
      notifyListeners(); // rebuild
    }

  }

  /*########## ENSURE DATA ##########*/

  Future<MarketPayload> ensureData() async { // function to load, and auto-refresh when empty

    final payload = await load(); // initial GET
    if (payload.isReady) { // real + predictions already cached
      return payload; // done
    }
    if (payload.isPending) { // real ready, forecasts in flight
      _startPolling(); // keep UI updating when callback lands
      return payload; // show chart with pending banner
    }
    // empty — kick pipeline and wait briefly for first OHLCV bars
    await refresh(); // POST /refresh + start poller
    for (var i = 0; i < 15; i++) { // ~30s for yfinance → Tiger real-only cache
      final current = market; // latest from poller / load
      if (current != null && !current.isEmpty) { // real (or ready) arrived
        return current; // splash can continue
      }
      await Future<void>.delayed(const Duration(seconds: 2)); // wait one interval
      try {
        await load(silent: true); // explicit GET between waits
      } catch (_) {
        // keep waiting through transient blips
      }
    }
    return market ?? payload; // may still be empty if backend/Tiger down

  }

  /*########## SYNC POLLING ##########*/

  void _syncPolling(MarketPayload payload) { // function to start/stop poll based on status

    if (payload.isPending) { // still waiting on GPU
      _startPolling(); // ensure timer running
      return; // done
    }
    if (payload.isReady) { // full snapshot
      _stopPolling(); // stop when settled
    }
    // empty: leave an existing poller alone (refresh owns that lifecycle)

  }

  /*########## START POLLING ##########*/

  void _startPolling() { // function to poll GET /market while pipeline / predictions run

    if (_pollTimer != null) { // already polling
      return; // reuse timer
    }
    _pollTicks = 0; // reset safety counter
    _pollTimer = Timer.periodic(_pollInterval, (_) async { // every few seconds
      _pollTicks += 1; // tick
      if (_pollTicks > _maxPollTicks) { // gave up waiting
        _stopPolling(); // stop timer
        error = 'Timed out waiting for market data'; // soft error
        notifyListeners(); // rebuild
        return; // done
      }
      try {
        final payload = await _api.getMarket(); // silent re-fetch
        market = payload; // update snapshot
        error = null; // clear transient errors
        notifyListeners(); // home / forecast rebuild
        if (payload.isReady) { // real + predictions
          _stopPolling(); // stop when fully ready
        }
      } catch (_) {
        // Keep polling through transient network blips while pipeline runs
      }
    }); // periodic poller

  }

  /*########## STOP POLLING ##########*/

  void _stopPolling() { // function to cancel pending-prediction poll timer

    _pollTimer?.cancel(); // stop
    _pollTimer = null; // clear handle
    _pollTicks = 0; // reset

  }

  /*########## DISPOSE ##########*/

  @override
  void dispose() { // function to cancel poller when store is torn down

    _stopPolling(); // free timer
    super.dispose(); // ChangeNotifier dispose

  }

}
