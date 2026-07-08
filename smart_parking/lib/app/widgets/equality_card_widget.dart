import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Widget carte d'égalité des chances DGAS — Sénégal
///
/// Reproduit fidèlement la carte physique délivrée par la
/// Direction Générale de l'Action Sociale.
///
/// Deux variantes :
/// - [EqualityCardWidget.recto] — face avec photo et infos
/// - [EqualityCardWidget.verso] — face avec QR code et symbole handicap
///
/// Utilisé dans RegisterScreen pour montrer l'utilisateur
/// comment prendre en photo sa carte et pour la validation ML Kit
class EqualityCardWidget extends StatelessWidget {
  final bool isVerso;

  const EqualityCardWidget({super.key, this.isVerso = false});

  const EqualityCardWidget.recto({super.key}) : isVerso = false;
  const EqualityCardWidget.verso({super.key}) : isVerso = true;

  @override
  Widget build(BuildContext context) {
    return isVerso ? _buildVerso() : _buildRecto();
  }

  // ── Styles communs ────────────────────────────────────────

  static const TextStyle _republiquStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle _labelStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    decoration: TextDecoration.underline,
  );

  static const TextStyle _contentStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  // ── Structure commune ─────────────────────────────────────

  Widget _buildCard(Widget body) {
    return Container(
      width: 300,
      height: 450,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 3,
            blurRadius: 7,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Card(
        elevation: 2,
        color: Colors.white,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white),
        ),
        child: Column(
          children: [
            // Header blanc — République du Sénégal
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
              ),
              height: 30,
              child: const Center(
                child: Text('République du Sénégal', style: _republiquStyle),
              ),
            ),

            // Header orange — DGAS
            Container(
              height: 75,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.orange,
                    Color.fromARGB(255, 255, 201, 39),
                    Colors.orange,
                    Color.fromARGB(255, 255, 201, 39),
                    Colors.red,
                  ],
                ),
                image: DecorationImage(
                  image: const AssetImage('assets/images/mayneed.png'),
                  fit: BoxFit.fitWidth,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.25),
                    BlendMode.dstATop,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      'DGAS',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Direction Générale de l'Action Sociale",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Corps de la carte
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  // ── Recto ─────────────────────────────────────────────────

  Widget _buildRecto() {
    return _buildCard(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            // Partie gauche
            Expanded(
              child: Column(
                children: [
                  // Photo
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        // Photo profil
                        Expanded(
                          child: Container(
                            color: Colors.grey.shade200,
                            child: Image.asset(
                              'assets/images/no_profile_picture_grey.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        // Infos
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Nom', style: _labelStyle),
                                const Text('NOM', style: _contentStyle),
                                const SizedBox(height: 6),
                                const Text('Prénom', style: _labelStyle),
                                const Text('PRENOM', style: _contentStyle),
                                const SizedBox(height: 6),
                                const Text('Date de naissance',
                                    style: _labelStyle),
                                const Text('JJ/MM/AAAA', style: _contentStyle),
                                const SizedBox(height: 6),
                                const Text('Lieu de naissance',
                                    style: _labelStyle),
                                const Text('LIEU', style: _contentStyle),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bas — code barre + Sénégal Émergent
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        // Code barre
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const RotatedBox(
                                        quarterTurns: -1,
                                        child: Text('12345678',
                                            style: TextStyle(fontSize: 8)),
                                      ),
                                      Expanded(
                                        child: Image.asset(
                                          'assets/images/barcode.jpg',
                                          fit: BoxFit.fitWidth,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Footer noir
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(20),
                                    ),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: const Column(
                                    children: [
                                      Text('ME',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 18)),
                                      Text('00000',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12)),
                                      Text('LIEU DELIVRANCE',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Logo Sénégal Émergent
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              'assets/images/snemergeant.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bande verticale droite
            Container(
              width: 25,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: const RotatedBox(
                quarterTurns: -1,
                child: Text(
                  'Certification de handicap',
                  style: TextStyle(
                    color: Colors.black,
                    letterSpacing: 2,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Verso ─────────────────────────────────────────────────

  Widget _buildVerso() {
    return _buildCard(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  // QR Code + numéro
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        // Numéro vertical
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: RotatedBox(
                            quarterTurns: -1,
                            child: Text(
                              '0000000000',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),

                        // QR Code
                        Expanded(
                          child: Center(
                            child: QrImageView(
                              data: '00000000000000000000',
                              size: 100,
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ),

                        // Symbole handicap
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              'assets/images/wheelchair.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Footer noir
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Column(
                      children: [
                        Text('ME',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18)),
                        Text('00000',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                        Text('LIEU DELIVRANCE',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bande verticale droite
            Container(
              width: 25,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: const RotatedBox(
                quarterTurns: -1,
                child: Text(
                  'Certification de handicap',
                  style: TextStyle(
                    color: Colors.black,
                    letterSpacing: 2,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
