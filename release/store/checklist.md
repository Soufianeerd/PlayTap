# Checklist de soumission — PlayTap 1.0.0

## Code / build

- [x] `flutter analyze` — 0 issue
- [x] `flutter test` — 79 passed, 3 skipped, 0 failed
- [x] `dart format --set-exit-if-changed .` — clean
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
- [ ] Captures d'écran uploadées (voir liste dans le rapport de sprint).
- [ ] Icône de l'app remplacée — **actuellement le logo Flutter par
      défaut**, pas une icône PlayTap (bloquant, voir rapport).
- [ ] Politique de confidentialité publiée à une URL accessible (le
      contenu de `privacy-policy-fr.md` doit être hébergé quelque part -
      Play Console exige une URL, pas un texte brut).
- [ ] Formulaire "Sécurité des données" Play Console rempli en cohérence
      avec `privacy-policy-fr.md` (aucune collecte à déclarer).
- [ ] Classification de contenu (content rating questionnaire).
- [ ] Coordonnées de contact développeur renseignées dans Play Console.

## iOS — bloquant avant soumission

- [ ] Compte Apple Developer Program (99 $/an) actif.
- [ ] Intégration Codemagic ↔ App Store Connect API key configurée (voir
      `codemagic.yaml` et le rapport de sprint pour la marche à suivre).
- [ ] Premier run du workflow `playtap-ios-release` sur Codemagic —
      **jamais exécuté**, à faire dès que le compte Apple Developer est
      prêt.
- [ ] Fiche App Store Connect remplie à partir de `app-store-fr.md`.
- [ ] URL de support renseignée (actuellement à définir).
- [ ] Politique de confidentialité (même URL que Android).
- [ ] Icône de l'app remplacée (même blocage que Android).
- [ ] Captures d'écran iPhone (et iPad si l'app les supporte) uploadées.

## Commun

- [ ] Icône de l'app — décision de design nécessaire avant toute
      soumission (Android ET iOS bloqués par le même problème).
- [ ] `release-notes-fr.md` collé dans les deux consoles.
- [ ] `app-review-notes.md` collé dans le champ "Notes pour la review"
      des deux stores.

## Non applicable / hors scope 1.0.0

- Apple Watch, Wear OS métier, synchronisation watch — non inclus dans
  ce build, donc rien à soumettre pour ces cibles.
