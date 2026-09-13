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

import 'package:flutter/material.dart'; // import Flutter Material UI toolkit

/*##### import local modules #####*/

import '../routes.dart'; // import named route constants
import '../services/app_services.dart'; // import market store for retry / refresh
import '../theme/app_theme.dart'; // import brand accent colors





/*##################################################*/
/*############### STATUS PAGES #####################*/
/*##################################################*/


/*########## EMPTY STATUS PAGE ##########*/

class EmptyStatusPage extends StatelessWidget { // class for "No market data yet" + refresh

  const EmptyStatusPage({super.key}); // default const constructor

  /*########## ON REFRESH ##########*/

  Future<void> _onRefresh(BuildContext context) async { // function to kick pipeline then route home

    try {
      await marketStore.refresh(force: true); // POST /refresh + poll
      if (!context.mounted) { // disposed
        return; // bail
      }
      final market = marketStore.market; // latest
      if (market == null || market.isEmpty) { // still empty
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Still no market data — check backend / Tiger')),
        ); // stay on empty
        return; // done
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.home); // data arrived
    } catch (_) {
      if (!context.mounted) { // disposed
        return; // bail
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.error); // hard failure
    }

  }

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build empty market state

    return Scaffold(
      appBar: AppBar(title: const Text('Market')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No market data yet',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Pull the latest SOL series from the backend to populate charts.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _onRefresh(context),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    ); // empty scaffold

  }

}


/*########## PENDING STATUS PAGE ##########*/

class PendingStatusPage extends StatefulWidget { // class for predictions_pending spinner state

  const PendingStatusPage({super.key}); // default const constructor

  @override
  State<PendingStatusPage> createState() => _PendingStatusPageState(); // create state

}


/*########## PENDING STATUS PAGE STATE ##########*/

class _PendingStatusPageState extends State<PendingStatusPage> { // class to poll until ready then go home

  /*########## INIT STATE ##########*/

  @override
  void initState() { // function to start polling when opened as a status demo / route

    super.initState(); // Flutter init
    marketStore.addListener(_onMarket); // watch store
    if (marketStore.market?.isPending != true) { // ensure poller if already pending elsewhere
      marketStore.load(silent: true); // kick a GET
    }

  }

  /*########## ON MARKET ##########*/

  void _onMarket() { // function to leave pending once forecasts arrive

    final market = marketStore.market; // snapshot
    if (market == null || !mounted) { // nothing / disposed
      return; // bail
    }
    if (market.isReady || (market.real.isNotEmpty && !market.isPending)) { // usable data
      Navigator.of(context).pushReplacementNamed(AppRoutes.home); // show chart
    }

  }

  /*########## DISPOSE ##########*/

  @override
  void dispose() { // function to detach store listener

    marketStore.removeListener(_onMarket); // stop watching
    super.dispose(); // Flutter dispose

  }

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build pending predictions state

    return Scaffold(
      appBar: AppBar(title: const Text('Forecast')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.purple), // LSTM wait spinner
              const SizedBox(height: 24),
              Text(
                'Generating predictions...',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Real prices are ready. Waiting on the GPU predictor callback.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    ); // pending scaffold

  }

}


/*########## ERROR STATUS PAGE ##########*/

class ErrorStatusPage extends StatelessWidget { // class for friendly network / auth error + retry

  const ErrorStatusPage({
    super.key,
    this.message = 'Something went wrong talking to the backend.',
  }); // optional custom message

  final String message; // error copy

  /*########## ON RETRY ##########*/

  Future<void> _onRetry(BuildContext context) async { // function to re-fetch /market then route

    try {
      final payload = await marketStore.ensureData(); // GET (+ refresh if empty)
      if (!context.mounted) { // disposed
        return; // bail
      }
      if (payload.isEmpty) { // still empty
        Navigator.of(context).pushReplacementNamed(AppRoutes.empty); // empty status
        return; // done
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.home); // data ok
    } catch (_) {
      if (!context.mounted) { // disposed
        return; // bail
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(marketStore.error ?? message)),
      ); // stay on error with toast
    }

  }

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build error / retry state

    final detail = marketStore.error ?? message; // prefer live error

    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.red),
              const SizedBox(height: 16),
              Text(
                'Couldn’t load data',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _onRetry(context),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    ); // error scaffold

  }

}
