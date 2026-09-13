/*############################################################*/
/*############### IMPORT / CREATE DEPENDENCIES ###############*/
/*############################################################*/


/*########## IMPORT DEPENDENCIES ##########*/

/*##### import necessary libraries #####*/

import 'package:flutter/material.dart'; // import Flutter Material UI toolkit

/*##### import local modules #####*/

import '../services/app_services.dart'; // import shared market store
import '../theme/app_theme.dart'; // import brand / direction colors





/*##################################################*/
/*############### FORECAST DETAIL PAGE #############*/
/*##################################################*/


/*########## FORECAST DETAIL PAGE ##########*/

class ForecastDetailPage extends StatelessWidget { // class for next-5 predicted closes + model blurb

  const ForecastDetailPage({super.key}); // default const constructor

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build forecast detail layout

    return ListenableBuilder(
      listenable: marketStore, // live updates when predictions arrive
      builder: (context, _) {
        final market = marketStore.market; // current snapshot
        final preds = market?.predictions ?? const []; // forecast series
        final lastClose = marketStore.lastClose; // baseline for up/down
        final model = preds.isNotEmpty ? (preds.first.modelVersion ?? 'bigru-attn-v1') : '-'; // model tag
        final generated = market?.updatedAt?.toLocal().toString() ?? '-'; // generated stamp
        final brightness = Theme.of(context).brightness; // light / dark content on gradient
        final onGradient = AppColors.onSolanaGradient(brightness); // white / black by mode

        return Scaffold(
          appBar: AppBar(title: const Text('SOL Forecast')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Next ${preds.isEmpty ? 5 : preds.length} predicted closes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (market?.isPending == true && preds.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.solanaCyan),
                      SizedBox(height: 16),
                      Text('Generating predictions...'),
                    ],
                  ),
                ) // pending spinner
              else if (preds.isEmpty)
                Text(
                  'No predictions yet. Pull to refresh on Home to run the pipeline.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ) // empty forecasts
              else
                ...List.generate(preds.length, (index) {
                  final point = preds[index]; // one forecast day
                  final prior = index == 0
                      ? lastClose
                      : preds[index - 1].predictedClose; // compare vs prior
                  final isUp = prior != null && point.predictedClose > prior; // positive day
                  final isDown = prior != null && point.predictedClose < prior; // negative day
                  final dayLabel = 'Day ${index + 1}'; // Day 1..N
                  final dateLabel =
                      point.time.toLocal().toIso8601String().split('T').first; // calendar day
                  final price = '\$${point.predictedClose.toStringAsFixed(2)}'; // formatted
                  final icon = isUp
                      ? Icons.trending_up
                      : (isDown ? Icons.trending_down : Icons.trending_flat);

                  if (isUp) { // bullish day → pulsing Solana gradient row
                    return _PulsingPositiveDay(
                      index: index,
                      icon: icon,
                      dayLabel: dayLabel,
                      dateLabel: dateLabel,
                      price: price,
                      onGradient: onGradient,
                    );
                  }

                  final color = isDown
                      ? AppColors.red
                      : Theme.of(context).colorScheme.onSurfaceVariant; // down / flat
                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: ListTile(
                      leading: Icon(icon, color: color),
                      title: Text(dayLabel),
                      subtitle: Text(dateLabel),
                      trailing: Text(
                        price,
                        style: TextStyle(color: color, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ); // flat / down prediction card
                }),
              const SizedBox(height: 16),
              Text(
                'Model: $model  ·  Generated: $generated',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ), // model_version + updated_at
              const SizedBox(height: 20),
              Text(
                'Why this forecast?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'LSTM trained on recent SOL daily closes from Tiger / yfinance history.',
                style: Theme.of(context).textTheme.bodyMedium,
              ), // short explain blurb
            ],
          ),
        ); // forecast scaffold
      },
    );

  }

}


/*########## PULSING POSITIVE DAY ##########*/

class _PulsingPositiveDay extends StatefulWidget { // class for bullish day with dot-style ping aura

  const _PulsingPositiveDay({
    required this.index,
    required this.icon,
    required this.dayLabel,
    required this.dateLabel,
    required this.price,
    required this.onGradient,
  }); // construct pulsing row

  final int index; // stagger phase like chart dots
  final IconData icon; // trending up
  final String dayLabel; // Day N
  final String dateLabel; // calendar day
  final String price; // formatted predicted close
  final Color onGradient; // white / black content

  @override
  State<_PulsingPositiveDay> createState() => _PulsingPositiveDayState(); // create state

}


/*########## PULSING POSITIVE DAY STATE ##########*/

class _PulsingPositiveDayState extends State<_PulsingPositiveDay>
    with SingleTickerProviderStateMixin { // class to drive expanding gradient ping

  late final AnimationController _ping; // 0..1 ping phase

  /*########## INIT STATE ##########*/

  @override
  void initState() { // function to start repeating ping

    super.initState(); // Flutter init
    _ping = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(); // match chart-dot timing

  }

  /*########## DISPOSE ##########*/

  @override
  void dispose() { // function to stop ping

    _ping.dispose(); // free ticker
    super.dispose(); // Flutter dispose

  }

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build pulsing gradient forecast row

    return AnimatedBuilder(
      animation: _ping,
      builder: (context, _) {
        final localT = (_ping.value + widget.index * 0.18) % 1.0; // stagger by day
        final eased = Curves.easeOut.transform(localT); // expand then fade
        final pingOpacity = (1.0 - eased) * 0.80; // twice-strong like dots
        final pingScale = 1.0 + eased * 0.10; // soft outward bloom
        final glowStrength = 0.55 + pingOpacity * 0.9; // glow breathes with ping

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: pingOpacity,
                child: Transform.scale(
                  scale: pingScale,
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppColors.solanaDiagonal,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ), // expanding translucent ping aura
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.solanaGlow(strength: glowStrength),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: AppColors.solanaDiagonal,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: Icon(widget.icon, color: widget.onGradient),
                      title: Text(
                        widget.dayLabel,
                        style: TextStyle(
                          color: widget.onGradient,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        widget.dateLabel,
                        style: TextStyle(
                          color: widget.onGradient.withValues(alpha: 0.85),
                        ),
                      ),
                      trailing: Text(
                        widget.price,
                        style: TextStyle(
                          color: widget.onGradient,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ), // solid gradient card on top
            ],
          ),
        ); // pulsing positive prediction
      },
    );

  }

}
