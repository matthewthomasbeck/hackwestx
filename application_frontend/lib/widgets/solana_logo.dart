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

import 'package:flutter/material.dart'; // import Flutter painting helpers

/*##### import local modules #####*/

import '../theme/app_theme.dart'; // import Solana pastel gradient





/*##################################################*/
/*############### SOLANA LOGO ######################*/
/*##################################################*/


/*########## SOLANA LOGO ##########*/

class SolanaLogo extends StatelessWidget { // class for classic three-bar Solana mark

  const SolanaLogo({
    super.key,
    this.size = 88,
  }); // construct sized logo

  final double size; // square bounding box

  /*########## BUILD ##########*/

  @override
  Widget build(BuildContext context) { // function to paint gradient Solana bars

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SolanaLogoPainter(),
      ),
    ); // three-bar mark

  }

}


/*########## SOLANA LOGO PAINTER ##########*/

class _SolanaLogoPainter extends CustomPainter { // class to draw Solana's three slanted bars

  /*########## PAINT ##########*/

  @override
  void paint(Canvas canvas, Size size) { // function to draw purple→cyan→green Solana bars

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = AppColors.solanaDiagonal.createShader(
        Offset.zero & size,
      ); // brand diagonal fill

    // Classic Solana mark: three parallel rounded parallelograms, same rightward slant
    final barH = size.height * 0.175; // each bar thickness
    final gap = size.height * 0.095; // space between bars
    final slant = size.width * 0.22; // horizontal slant offset
    final inset = size.width * 0.08; // side padding
    final topY = (size.height - (barH * 3 + gap * 2)) / 2; // vertically center stack

    for (var i = 0; i < 3; i++) { // top → bottom bars
      final y = topY + i * (barH + gap); // bar top
      final path = Path()
        ..moveTo(inset + slant, y)
        ..lineTo(size.width - inset, y)
        ..lineTo(size.width - inset - slant, y + barH)
        ..lineTo(inset, y + barH)
        ..close(); // parallelogram bar
      canvas.drawPath(path, paint); // Solana bar
    }

  }

  /*########## SHOULD REPAINT ##########*/

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false; // static mark

}
