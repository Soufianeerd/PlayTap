# Checklist de soumission — PlayTap 1.0.0

## Code / build

- [x] `flutter analyze` — 0 issue
- [x] `flutter test` — 80 passed, 3 skipped, 0 failed (includes a
      regression test for the `historyProvider` freeze fix below)
- [x] `dart format --set-exit-if-changed .` — clean
- [x] P0 fixé : `historyProvider` (Historique) ne se figeait plus après la
      première session terminée — converti en `StreamProvider` réactif sur
      `SessionRepository.watchCompletedSessions()`, même pattern que
      `activeSessionProvider`. Voir `history_page.dart` /
      `session_repository.dart`.
- [x] P1 fixé : `TimerSessionController._appendAndReload` protégé par le
      même garde `_finalizeInFlight` que `complete()` — évite une écriture
      concurrente en double si pause/resume/lap tombe pile au moment où un
      countdown se termine tout seul.
- [x] Version bumpée à `1.0.0+1` (`pubspec.yaml`, propagée à Android et
      iOS automatiquement)
- [x] Aucun placeholder / "en construction" accessible depuis l'UI
      (Training, Custom, sports non implémentés masqués)
- [x] `flutter build appbundle --release` — .aab réel généré et signé
- [x] `flutter build apk --release` — .apk réel généré et signé (pour
      tests sur device/émulateur)
- [x] Signing release Android — clé d'upload générée localement,
      **non committée** (voir `docs/RELEASE_CHECKLIST.md`)

## Android — bloquant avant soumission

- [ ] **Sauvegarder `mobile/android/playtap-upload-keystore.jks` et
      `mobile/android/key.properties` hors de cette machine** (gestionnaire
      de mots de passe + backup externe). Ces fichiers ne sont pas dans
      git et n'existent qu'ici — leur perte empêchera toute mise à jour
      future de l'app sous le même listing Play Store.
- [ ] Compte Google Play Console (créé et payé — frais unique).
- [ ] Fiche Play Store remplie à partir de `google-play-fr.md`.
- [x] Icône de l'app — icône finale "direction-a-pulse" (fond noir,
      anneau violet, point lime) intégrée sur Android ET iOS, plus
      `release/icon/source/icon-1024.png` et
      `release/store/assets/play-store-icon-512.png`. Ce n'est plus le
      logo Flutter par défaut.
- [x] 6 captures d'écran Store générées dans
      `release/store/assets/screenshots/` (Home, Nouveau score, Score 2
      joueurs, Score 4 joueurs, Timer, Historique — thème clair, device
      1080×2400). À uploader dans Play Console / App Store Connect.
- [x] Feature graphic Google Play générée :
      `release/store/assets/feature-graphic.png` (1024×500).
- [ ] Politique de confidentialité publiée à une URL accessible (le
      contenu de `privacy-policy-fr.md` doit être hébergé quelque part -
      Play Console exige une URL, pas un texte brut).
- [ ] Formulaire "Sécurité des données" Play Console rempli en cohérence
      avec `privacy-policy-fr.md` (aucune collecte à déclarer).
- [ ] Classification de contenu (content rating questionnaire).
- [ ] Coordonnées de contact développeur renseignées dans Play Console.

## iOS — bloquant avant soumission

- [ ] Compte Apple Developer Program (99 $/an) actif.
- [ ] **App Store Connect : créer la fiche app et remplacer le
      placeholder `APP_STORE_APPLE_ID: 0000000000` dans `codemagic.yaml`
      par le vrai Apple ID numérique** — bloque tout run du pipeline tant
      que ce n'est pas fait.
- [ ] Premier run du workflow `playtap-ios-release` sur Codemagic —
      **jamais exécuté**, à faire dès que le compte Apple Developer + la
      fiche App Store Connect sont prêts. Ne pas considérer le build iOS
      comme validé avant un run réel réussi.
- [ ] Fiche App Store Connect remplie à partir de `app-store-fr.md`.
- [ ] URL de support renseignée (actuellement à définir — voir
      `app-store-fr.md`).
- [ ] Politique de confidentialité (même URL que Android).
- [x] Icône de l'app — intégrée dans
      `mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/` (même icône
      finale que Android, voir ci-dessus).
- [ ] Captures d'écran iPhone uploadées — celles générées pour Android
      (`release/store/assets/screenshots/`) viennent d'un device Android ;
      il faudra des captures iPhone une fois un premier build Codemagic
      disponible (pas d'iPad, l'app est iPhone-only).

## Commun

- [ ] `release-notes-fr.md` collé dans les deux consoles.
- [ ] `app-review-notes.md` collé dans le champ "Notes pour la review"
      des deux stores.

## Non applicable / hors scope 1.0.0

- Apple Watch, Wear OS métier, synchronisation watch — non inclus dans
  ce build, donc rien à soumettre pour ces cibles.
