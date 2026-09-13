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

import '../services/app_services.dart'; // import shared market store
import '../theme/app_theme.dart'; // import brand / direction colors





/*##################################################*/
/*############### FORECAST DETAIL PAGE #############*/
/*##################################################*/


/*########## FORECAST DETAIL PAGE ##########*/

class ForecastDetailPage extends StatelessWidget { // class for next-3 predicted closes + model blurb

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
        final model = preds.isNotEmpty ? (preds.first.modelVersion ?? 'lstm-v1') : '—'; // model tag
        final generated = market?.updatedAt?.toLocal().toString() ?? '—'; // generated stamp

        return Scaffold(
          appBar: AppBar(title: const Text('SOL Forecast')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Next 3 predicted closes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (market?.isPending == true && preds.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.purple),
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
                ...List.generate(preds.take(3).length, (index) {
                  final point = preds[index]; // one forecast day
                  final prior = index == 0
                      ? lastClose
                      : preds[index - 1].predictedClose; // compare vs prior
                  final direction = prior == null
                      ? 'neutral'
                      : (point.predictedClose > prior
                          ? 'up'
                          : (point.predictedClose < prior ? 'down' : 'neutral')); // direction
                  final color = switch (direction) {
                    'up' => AppColors.green,
                    'down' => AppColors.red,
                    _ => Theme.of(context).colorScheme.onSurfaceVariant,
                  }; // direction color
                  final icon = switch (direction) {
                    'up' => Icons.trending_up,
                    'down' => Icons.trending_down,
                    _ => Icons.trending_flat,
                  }; // direction icon
                  final dayLabel = 'Day ${index + 1}'; // Day 1..3
                  final price = '\$${point.predictedClose.toStringAsFixed(2)}'; // formatted
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(icon, color: color),
                      title: Text(dayLabel),
                      subtitle: Text(
                        point.time.toLocal().toIso8601String().split('T').first,
                      ), // forecast calendar day
                      trailing: Text(
                        price,
                        style: TextStyle(color: color, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ); // one forecast day card
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
