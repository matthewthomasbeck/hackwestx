/*############################################################*/
/*############### IMPORT / CREATE DEPENDENCIES ###############*/
/*############################################################*/


/*########## IMPORT DEPENDENCIES ##########*/

/*##### import necessary libraries #####*/

import 'package:flutter/material.dart'; // import Flutter Material UI toolkit

/*##### import local modules #####*/

import '../models/portfolio.dart'; // import PaperOrderArgs / PaperTrade
import '../routes.dart'; // import named route constants
import '../services/app_services.dart'; // import portfolioStore for paper fill
import '../theme/app_theme.dart'; // import success green glow tokens





/*##################################################*/
/*############### TRADE CONFIRM PAGE ###############*/
/*##################################################*/


/*########## TRADE CONFIRM PAGE ##########*/

class TradeConfirmPage extends StatefulWidget { // class for confirm step then success receipt

  const TradeConfirmPage({super.key}); // default const constructor

  @override
  State<TradeConfirmPage> createState() => _TradeConfirmPageState(); // create state

}


/*########## TRADE CONFIRM PAGE STATE ##########*/

class _TradeConfirmPageState extends State<TradeConfirmPage> { // class to toggle confirm vs receipt

  bool _confirmed = false; // False = review, True = receipt
  bool _submitting = false; // guard double-tap
  PaperTrade? _filled; // receipt after successful fill
  String? _error; // fill failure message

  /*########## ORDER ARGS ##########*/

  PaperOrderArgs? get _order { // function to read Buy/Sell handoff args

    final args = ModalRoute.of(context)?.settings.arguments; // route args
    if (args is PaperOrderArgs) { // expected type
      return args; // pending order
    }
    return null; // opened without trade flow

  }

  /*########## CONFIRM ##########*/

  Future<void> _confirm() async { // function to fill paper buy/sell then show receipt

    final order = _order; // pending review
    if (order == null || _submitting) { // nothing to fill / in flight
      return; // bail
    }

    setState(() {
      _submitting = true; // lock CTA
      _error = null; // clear prior
    });

    try {
      final PaperTrade trade;
      if (order.isSell) { // exit position
        trade = portfolioStore.sell(
          solAmount: order.solAmount,
          price: order.price,
        ); // credit cash / debit SOL
      } else { // enter / add
        trade = portfolioStore.buy(
          usdAmount: order.usdAmount,
          price: order.price,
        ); // debit cash / credit SOL
      }
      if (!mounted) { // disposed during await
        return; // bail
      }
      setState(() {
        _filled = trade; // receipt fields
        _confirmed = true; // flip to receipt view
        _submitting = false; // unlock
      });
    } catch (e) {
      if (!mounted) { // disposed during await
        return; // bail
      }
      setState(() {
        _submitting = false; // unlock
        _error = e.toString(); // show under summary
      });
    }

  }

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build confirm or receipt UI

    final order = _order; // pending or null
    final filled = _filled; // post-fill trade
    final isSell = filled?.side == 'sell' || order?.isSell == true; // label mode

    if (_confirmed && filled != null) { // success receipt
      return Scaffold(
        appBar: AppBar(title: const Text('Trade Receipt')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.check_circle,
                size: 72,
                color: AppColors.green,
                shadows: [
                  Shadow(color: AppColors.green.withValues(alpha: 0.55), blurRadius: 18),
                ],
              ), // success check + glow
              const SizedBox(height: 16),
              Text(
                isSell ? 'Paper sell submitted' : 'Paper buy submitted',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Trade ID: ${filled.id}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              _SummaryRow(
                label: isSell ? 'USD received' : 'USD spent',
                value: '\$${filled.usdAmount.toStringAsFixed(2)}',
              ),
              _SummaryRow(
                label: isSell ? 'SOL sold' : 'SOL bought',
                value: filled.solAmount.toStringAsFixed(4),
              ),
              _SummaryRow(
                label: 'Price used',
                value: '\$${filled.price.toStringAsFixed(2)}',
              ),
              _SummaryRow(
                label: 'Timestamp',
                value: _formatTime(filled.timestamp),
              ),
              const Spacer(),
              Builder(
                builder: (context) {
                  final brightness = Theme.of(context).brightness;
                  final onGradient = AppColors.onSolanaGradient(brightness);
                  final isDark = brightness == Brightness.dark;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: AppColors.solanaGlow(strength: 0.7),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(context)
                                .pushNamed(AppRoutes.tradeHistory),
                            borderRadius: BorderRadius.circular(999),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: AppColors.solanaDiagonal,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  'View History',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: onGradient,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ), // Solana-gradient history CTA
                      const SizedBox(height: 12),
                      Material(
                        color: isDark ? AppColors.blackMid : AppColors.whiteMid,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.home,
                            (route) => false,
                          ),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.blackLightest
                                    : AppColors.whiteDarkest,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'Back to Home',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: isDark
                                        ? AppColors.whiteLightest
                                        : AppColors.blackDarkest,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                      ), // dark / light neutral home CTA
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ); // receipt scaffold
    }

    if (order == null) { // deep-link / missing args
      return Scaffold(
        appBar: AppBar(title: const Text('Confirm Trade')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No pending order. Start from Buy or Sell SOL.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed(
                    AppRoutes.buySol,
                  ),
                  child: const Text('Buy SOL'),
                ),
              ],
            ),
          ),
        ),
      ); // missing-order scaffold
    }

    return Scaffold(
      appBar: AppBar(title: Text(isSell ? 'Confirm Sell' : 'Confirm Buy')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Order summary', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _SummaryRow(
              label: isSell ? 'USD received' : 'USD spent',
              value: '\$${order.usdAmount.toStringAsFixed(2)}',
            ),
            _SummaryRow(
              label: isSell ? 'SOL sold' : 'SOL bought',
              value: order.solAmount.toStringAsFixed(4),
            ),
            _SummaryRow(
              label: 'Price used',
              value: '\$${order.price.toStringAsFixed(2)}',
            ),
            _SummaryRow(
              label: 'Timestamp',
              value: _formatTime(DateTime.now()),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const Spacer(),
            Builder(
              builder: (context) {
                final brightness = Theme.of(context).brightness;
                final onGradient = AppColors.onSolanaGradient(brightness);
                final canSubmit = !_submitting;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: canSubmit
                        ? AppColors.solanaGlow(strength: 0.7)
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: canSubmit ? _confirm : null,
                      borderRadius: BorderRadius.circular(999),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: canSubmit ? AppColors.solanaDiagonal : null,
                          color: canSubmit
                              ? null
                              : Theme.of(context).disabledColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            _submitting ? 'Submitting…' : 'Confirm',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: onGradient,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ); // Solana-gradient confirm CTA
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.whiteLightest
                    : AppColors.blackDarkest,
              ),
              child: const Text('Cancel'),
            ), // theme-neutral text cancel (not Material blue)
          ],
        ),
      ),
    ); // confirm scaffold

  }

  /*########## FORMAT TIME ##########*/

  String _formatTime(DateTime dt) { // function to show local fill / preview time

    final local = dt.toLocal(); // device zone
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min'; // compact stamp

  }

}


/*########## SUMMARY ROW ##########*/

class _SummaryRow extends StatelessWidget { // class for order summary label / value row

  const _SummaryRow({required this.label, required this.value}); // construct row

  final String label; // left label
  final String value; // right value

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to build one summary row

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );

  }

}
