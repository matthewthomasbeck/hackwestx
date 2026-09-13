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
/*############### ONBOARDING PAGE ##################*/
/*##################################################*/


/*########## ONBOARDING PAGE ##########*/

class OnboardingPage extends StatefulWidget { // class for 3 swipeable intro cards + Get Started

  const OnboardingPage({super.key}); // default const constructor

  @override
  State<OnboardingPage> createState() => _OnboardingPageState(); // create state

}


/*########## ONBOARDING PAGE STATE ##########*/

class _OnboardingPageState extends State<OnboardingPage> { // class to track PageView index

  final _controller = PageController(); // swipe controller
  int _index = 0; // current card index

  static const _cards = [ // intro card copy
    (
      title: 'AI forecasts SOL',
      body: 'An LSTM predicts the next few daily closes from recent Solana price history.',
      icon: Icons.auto_graph,
    ),
    (
      title: 'Paper-trade with fake money',
      body: 'Buy SOL in a sandbox ledger. No real wallet risk — practice the forecast → trade loop.',
      icon: Icons.account_balance_wallet_outlined,
    ),
    (
      title: 'Track results over time',
      body: 'Compare predictions vs reality and see how your paper portfolio performs.',
      icon: Icons.insights_outlined,
    ),
  ];

  /*########## DISPOSE ##########*/

  @override
  void dispose() { // function to dispose PageController

    _controller.dispose(); // free controller
    super.dispose(); // Flutter dispose

  }

  /*########## FINISH ##########*/

  void _finish() { // function to mark onboarding done and go home

    // TODO: persist onboardingComplete flag (shared_preferences)
    Navigator.of(context).pushReplacementNamed(AppRoutes.home); // enter main app

  }

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build swipeable onboarding

    final isLast = _index == _cards.length - 1; // last card check

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ), // skip onboarding
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _cards.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final card = _cards[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(card.icon, size: 72, color: AppColors.purple), // card icon
                        const SizedBox(height: 24),
                        Text(
                          card.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          card.body,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ); // one intro card
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _cards.length,
                (i) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index ? AppColors.blue : Colors.grey.shade500,
                  ),
                ),
              ),
            ), // page dots
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (isLast) {
                      _finish(); // done
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      ); // next card
                    }
                  },
                  child: Text(isLast ? 'Get Started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    ); // onboarding scaffold

  }

}
