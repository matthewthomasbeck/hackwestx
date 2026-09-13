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

    // TODO: bind to MarketPayload.predictions (up to 3 days)
    final stubDays = [
      ('Day 1', '\$—', 'neutral'),
      ('Day 2', '\$—', 'up'),
      ('Day 3', '\$—', 'down'),
    ]; // placeholder cards until API wired

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
          ...stubDays.map((day) {
            final (label, price, direction) = day;
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
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(icon, color: color),
                title: Text(label),
                trailing: Text(price, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              ),
            ); // one forecast day card
          }),
          const SizedBox(height: 16),
          Text(
            'Model: —  ·  Generated: —',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ), // model_version + updated_at stubs
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

  }

}
