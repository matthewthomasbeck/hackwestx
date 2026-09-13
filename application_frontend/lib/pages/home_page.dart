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
import '../theme/app_theme.dart'; // import brand color tokens





/*##################################################*/
/*############### HOME PAGE ########################*/
/*##################################################*/


/*########## HOME PAGE ##########*/

class HomePage extends StatelessWidget { // class for SOL price header + chart + quick actions

  const HomePage({super.key}); // default const constructor

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build home chart scaffold

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOL'),
        actions: [
          IconButton(
            tooltip: 'Refresh market',
            onPressed: () {
              // TODO: call ApiService.refreshMarket() then getMarket()
            },
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
        onRefresh: () async {
          // TODO: pull-to-refresh → GET /api/v1/market
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '\$—',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ), // current SOL price placeholder
            Text(
              '—%  ·  last updated —',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ), // % change + timestamp placeholder
            const SizedBox(height: 20),
            Container(
              height: 240,
              alignment: Alignment.center,
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
              child: const Text(
                'Chart placeholder\nreal (solid) + predictions (dashed)',
                textAlign: TextAlign.center,
              ), // chart stub until fl_chart / custom painter wired
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
            const SizedBox(height: 24),
            Text(
              'Status demos',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.empty),
                  child: const Text('Empty'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.pending),
                  child: const Text('Pending'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.error),
                  child: const Text('Error'),
                ),
              ],
            ), // temporary links to status pages for scaffolding
          ],
        ),
      ),
    ); // home scaffold

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
