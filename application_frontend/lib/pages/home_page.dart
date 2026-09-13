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
import '../services/app_services.dart'; // import shared market store
import '../theme/app_theme.dart'; // import brand color tokens
import '../widgets/market_chart.dart'; // import real + prediction chart





/*##################################################*/
/*############### HOME PAGE ########################*/
/*##################################################*/


/*########## HOME PAGE ##########*/

class HomePage extends StatefulWidget { // class for SOL price header + chart + quick actions

  const HomePage({super.key}); // default const constructor

  @override
  State<HomePage> createState() => _HomePageState(); // create state

}


/*########## HOME PAGE STATE ##########*/

class _HomePageState extends State<HomePage> { // class to bind MarketStore into home UI

  /*########## INIT STATE ##########*/

  @override
  void initState() { // function to ensure market snapshot exists on first home entry

    super.initState(); // Flutter init
    if (marketStore.market == null && !marketStore.loading) { // cold open without splash fetch
      marketStore.ensureData(); // load (+ refresh if empty)
    }

  }

  /*########## ON REFRESH ##########*/

  Future<void> _onRefresh({bool force = false}) async { // function to POST /refresh then poll

    try {
      await marketStore.refresh(force: force); // kick pipeline + poll
    } catch (_) {
      if (!mounted) { // disposed
        return; // bail
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(marketStore.error ?? 'Refresh failed')),
      ); // soft error toast
    }

  }

  /*########## FORMAT PRICE ##########*/

  String _formatPrice(double? price) { // function to format USD price or em dash

    if (price == null) { // unknown
      return '\$—'; // placeholder
    }
    return '\$${price.toStringAsFixed(2)}'; // two decimals

  }

  /*########## FORMAT CHANGE ##########*/

  String _formatChange(double? change) { // function to format % change or em dash

    if (change == null) { // unknown
      return '—%'; // placeholder
    }
    final sign = change >= 0 ? '+' : ''; // explicit plus
    return '$sign${change.toStringAsFixed(2)}%'; // percent

  }

  /*########## FORMAT UPDATED ##########*/

  String _formatUpdated(DateTime? updatedAt) { // function to format last-updated stamp

    if (updatedAt == null) { // unknown
      return '—'; // placeholder
    }
    final local = updatedAt.toLocal(); // device tz
    final hh = local.hour.toString().padLeft(2, '0'); // hour
    final mm = local.minute.toString().padLeft(2, '0'); // minute
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $hh:$mm'; // compact stamp

  }

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build home chart scaffold

    return ListenableBuilder(
      listenable: marketStore, // rebuild when /market updates
      builder: (context, _) {
        final market = marketStore.market; // current snapshot
        final price = marketStore.lastClose; // latest close
        final change = marketStore.percentChange; // day change
        final changeColor = change == null
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : (change >= 0 ? AppColors.green : AppColors.red); // direction color
        final pending = market?.isPending == true || marketStore.refreshing; // forecasts in flight

        return Scaffold(
          appBar: AppBar(
            title: const Text('SOL'),
            actions: [
              if (pending)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ), // subtle pending indicator
              IconButton(
                tooltip: 'Refresh market',
                onPressed: marketStore.refreshing ? null : () => _onRefresh(force: true),
                icon: const Icon(Icons.refresh),
              ), // POST /market/refresh
              IconButton(
                tooltip: 'Settings',
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => _onRefresh(force: true), // pull-to-refresh
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(), // allow pull when short
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  _formatPrice(price),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ), // current SOL price
                Text(
                  '${_formatChange(change)}  ·  last updated ${_formatUpdated(market?.updatedAt)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: changeColor,
                      ),
                ), // % change + timestamp
                if (pending) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Generating predictions...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ), // pending copy while GPU runs
                ],
                if (marketStore.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    marketStore.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.red,
                        ),
                  ), // last error
                ],
                const SizedBox(height: 20),
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.purple.withValues(alpha: 0.18),
                        AppColors.blue.withValues(alpha: 0.12),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.35),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: MarketChart(
                      real: market?.real ?? const [],
                      predictions: market?.predictions ?? const [],
                    ), // real solid + predictions dashed
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _QuickAction(
                      label: 'Forecast',
                      icon: Icons.timeline,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.forecastDetail),
                    ),
                    _QuickAction(
                      label: 'Portfolio',
                      icon: Icons.pie_chart_outline,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.portfolio),
                    ),
                    _QuickAction(
                      label: 'Buy SOL',
                      icon: Icons.shopping_cart_outlined,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.buySol),
                    ),
                    _QuickAction(
                      label: 'History',
                      icon: Icons.history,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.tradeHistory),
                    ),
                  ],
                ), // quick-action row
              ],
            ),
          ),
        ); // home scaffold
      },
    );

  }

}


/*########## QUICK ACTION ##########*/

class _QuickAction extends StatelessWidget { // class for compact home navigation chip/button

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  }); // construct action

  final String label; // button label
  final IconData icon; // leading icon
  final VoidCallback onTap; // navigation callback

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build one quick-action button

    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    ); // tonal action

  }

}
