/*############################################################*/
/*############### IMPORT / CREATE DEPENDENCIES ###############*/
/*############################################################*/


/*########## IMPORT DEPENDENCIES ##########*/

/*##### import necessary libraries #####*/

import 'package:flutter/material.dart'; // import Flutter Material UI toolkit

/*##### import local modules #####*/

import '../models/market.dart'; // import OHLCV / prediction points for chart windowing
import '../routes.dart'; // import named route constants
import '../services/app_services.dart'; // import shared market store
import '../theme/app_theme.dart'; // import brand color tokens
import '../widgets/market_chart.dart'; // import real + prediction chart





/*##################################################*/
/*############### CHART TIME RANGE #################*/
/*##################################################*/


/*########## CHART TIME RANGE ##########*/

enum _ChartTimeRange { // enum for ML-portfolio-style chart window buttons

  week(7, '1W'), // last ~7 trading days
  month(30, '1M'), // last ~30 days
  threeMonths(90, '3M'), // last ~90 days
  year(365, 'YTD'), // last ~365 days
  max(null, 'Max'); // full history from API

  const _ChartTimeRange(this.days, this.label); // days null = no trim

  final int? days; // lookback in calendar days; null keeps entire series
  final String label; // compact button label (matches small-screen MLP buttons)

}


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

  _ChartTimeRange _chartRange = _ChartTimeRange.week; // default to one week like MLP

  /*########## INIT STATE ##########*/

  @override
  void initState() { // function to ensure market snapshot exists on first home entry

    super.initState(); // Flutter init
    if (marketStore.market == null && !marketStore.loading) { // cold open without splash fetch
      marketStore.ensureData(); // load (+ refresh if empty)
    }

  }

  /*########## WINDOW REAL SERIES ##########*/

  List<OhlcvPoint> _windowedReal(List<OhlcvPoint> real) { // function to trim history to selected range

    final days = _chartRange.days; // lookback or null for max
    if (days == null || real.isEmpty) { // Max / empty
      return real; // full series
    }
    final cutoff = real.last.time.subtract(Duration(days: days)); // inclusive window from latest bar
    return real.where((p) => !p.time.isBefore(cutoff)).toList(); // keep bars in window

  }

  /*########## RANGE PERCENT CHANGE ##########*/

  double? _rangePercentChange(List<OhlcvPoint> real) { // function to % move over selected chart window

    final windowed = _windowedReal(real); // same bars as chart range
    if (windowed.length < 2) { // need start + end
      return null; // unknown
    }
    final start = windowed.first.close; // close at start of window
    final end = windowed.last.close; // latest close
    if (start == 0) { // avoid divide-by-zero
      return null; // unknown
    }
    return ((end - start) / start) * 100.0; // window return

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
        final change = _rangePercentChange(market?.real ?? const []); // % over active 1W/1M/… window
        final muted = Theme.of(context).colorScheme.onSurfaceVariant; // timestamp / neutral
        final changeColor = change == null
            ? muted
            : (change >= 0 ? AppColors.green : AppColors.red); // green up / red down
        final pending = market?.isPending == true || marketStore.refreshing; // forecasts in flight

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 84, // room for enlarged SOL title
            title: Text(
              'SOL',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    height: 1.0,
                  ),
            ), // largest brand mark in the app bar
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
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ), // SOL price — second-largest after SOL title
                Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.titleMedium,
                    children: [
                      TextSpan(
                        text: _formatChange(change),
                        style: TextStyle(
                          color: changeColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ), // range % green/red
                      TextSpan(
                        text: '  ·  last updated ${_formatUpdated(market?.updatedAt)}',
                        style: TextStyle(color: muted),
                      ), // neutral stamp
                    ],
                  ),
                ), // enlarged % change + timestamp
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
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppColors.solanaDiagonal, // gradient as border
                    boxShadow: AppColors.solanaGlow(strength: 0.85),
                  ),
                  padding: const EdgeInsets.all(3), // border thickness
                  child: Container(
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      color: Theme.of(context).scaffoldBackgroundColor, // match page canvas (white / black)
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: MarketChart(
                        real: _windowedReal(market?.real ?? const []),
                        predictions: market?.predictions ?? const [],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _ChartTimeRangeBar(
                  selected: _chartRange,
                  onChanged: (range) => setState(() => _chartRange = range),
                ), // squarish purple 1W / 1M / 3M / YTD / Max
                const SizedBox(height: 28),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _QuickAction(
                      label: 'Forecast',
                      icon: Icons.timeline,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.forecastDetail),
                    ),
                    const SizedBox(height: 22),
                    _QuickAction(
                      label: 'Portfolio',
                      icon: Icons.pie_chart_outline,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.portfolio),
                    ),
                    const SizedBox(height: 22),
                    _QuickAction(
                      label: 'Buy SOL',
                      icon: Icons.shopping_cart_outlined,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.buySol),
                    ),
                    const SizedBox(height: 22),
                    _QuickAction(
                      label: 'Sell SOL',
                      icon: Icons.sell_outlined,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.sellSol),
                    ),
                    const SizedBox(height: 22),
                    _QuickAction(
                      label: 'History',
                      icon: Icons.history,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.tradeHistory),
                    ),
                  ],
                ), // full-width stacked Solana-gradient actions
              ],
            ),
          ),
        ); // home scaffold
      },
    );

  }

}


/*########## CHART TIME RANGE BAR ##########*/

class _ChartTimeRangeBar extends StatelessWidget { // class for MLP-style timeframe toggles under chart

  const _ChartTimeRangeBar({
    required this.selected,
    required this.onChanged,
  }); // construct range bar

  final _ChartTimeRange selected; // active window
  final ValueChanged<_ChartTimeRange> onChanged; // selection callback

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build centered 1W..Max row

    return Row(
      children: [
        for (final range in _ChartTimeRange.values) ...[
          if (range != _ChartTimeRange.values.first) const SizedBox(width: 6),
          Expanded(
            child: _ChartTimeRangeButton(
              label: range.label,
              selected: range == selected,
              onTap: () => onChanged(range),
            ),
          ),
        ],
      ],
    ); // equal-width timeframe row

  }

}


/*########## CHART TIME RANGE BUTTON ##########*/

class _ChartTimeRangeButton extends StatelessWidget { // class for squarish purple timeframe toggle

  const _ChartTimeRangeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  }); // construct button

  final String label; // 1W / 1M / …
  final bool selected; // active highlight
  final VoidCallback onTap; // select range

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build squarish purple range chip

    final brightness = Theme.of(context).brightness; // dark / light selected fill
    final bg = selected
        ? AppColors.timeframeSelectedFill(brightness) // mid dark / mid light
        : AppColors.solanaPurple; // inactive = purple fill
    final fg = selected
        ? AppColors.timeframeSelectedForeground(brightness)
        : AppColors.whiteLightest; // contrast on purple
    final borderColor = selected ? fg : AppColors.solanaPurple; // selected border matches text

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(4), // squarish (not pill)
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    ); // squarish purple toggle

  }

}


/*########## QUICK ACTION ##########*/

class _QuickAction extends StatelessWidget { // class for ovular Solana-gradient home nav button

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
  Widget build(BuildContext context) { // function to build one full-width gradient pill

    final onGradient = AppColors.onSolanaGradient(Theme.of(context).brightness); // white / black by mode

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: AppColors.solanaGlow(strength: 0.7), // soft Solana aura
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999), // ovular / pill
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppColors.solanaDiagonal, // purple LL → cyan → green UR
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22, color: onGradient),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: onGradient,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ); // ovular Solana gradient action

  }

}
