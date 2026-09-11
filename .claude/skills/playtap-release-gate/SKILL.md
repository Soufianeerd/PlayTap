---
name: playtap-release-gate
description: Checklist obligatoire avant toute release PlayTap (analyze, tests, builds natifs, flows critiques, audits permissions/privacy/dead-buttons/crash/accessibilité, tests offline et session recovery). Utiliser avant de déclarer une release prête ou de publier une version.
---

# PlayTap — Release Gate

## Règle absolue

**Pas de release si un parcours P0 est cassé.** Un parcours P0 = démarrer
une activité, l'exécuter (score/timer/interval/workout), la terminer,
retrouver son historique. Voir la définition de "Done" dans
`playtap-product` — cette checklist est le niveau release globale,
au-dessus du niveau feature individuelle.

## Checklist avant release

Exécuter réellement chaque étape (voir `CLAUDE.md` — règle de
vérification), pas seulement la lire dans le code :

1. **`flutter analyze`** — zéro erreur, warnings nouveaux justifiés.
2. **`flutter test`** — tous les tests passent, y compris les tests
   déterministes des moteurs (voir `playtap-score-engine`,
   `playtap-timer-engine`, `playtap-interval-engine`,
   `playtap-workout-engine`).
3. **Build natif Apple** — via XcodeBuildMCP, build simulateur (et device
   si signing dispo) pour l'app iOS ET la target watchOS.
4. **Build natif Android/Wear** — build de l'app Android ET du module
   Wear OS.
5. **Tests des flows critiques** — via Mobile MCP et/ou XcodeBuildMCP UI
   automation : démarrer chaque catégorie (Score/Timer/Training/Custom),
   dérouler jusqu'à la fin, vérifier l'historique.
6. **Audit permissions** — chaque permission demandée (notifications,
   Bluetooth/companion, etc.) a une justification claire et un usage
   réel ; aucune permission inutilisée ou orpheline.
7. **Audit privacy** — aucune donnée envoyée à un tiers sans nécessité ;
   cohérent avec le principe offline-first (voir `playtap-offline-first`).
8. **Audit dead buttons** — chaque bouton/action visible à l'écran a un
   effet ; aucun élément d'UI non connecté.
9. **Audit crash** — consulter les logs/crash reports (Mobile MCP
   `mobile_get_crash`/`mobile_list_crashes`, ou logs XcodeBuildMCP) après
   les tests de flows ; zéro crash non résolu sur les flows P0.
10. **Accessibility checks** — tailles de police et cibles tactiles
    conformes aux règles `playtap-watch-ux` côté montre, labels
    accessibles côté phone.
11. **Test offline** — mode avion activé, dérouler un flow complet
    (Score, Timer, Training) de bout en bout sans erreur ni blocage.
12. **Test session recovery** — kill forcé de l'app/process en pleine
    session, relancer, vérifier la reprise correcte de l'état (voir
    `playtap-offline-first` et `playtap-timer-engine` pour les règles de
    recovery).

## Ordre recommandé

Analyze → tests unitaires → builds natifs → flows critiques (Mobile MCP)
→ audits (permissions/privacy/dead buttons/crash/accessibilité) → offline
→ session recovery. Ne pas sauter d'étape même si les précédentes sont
passées — chaque étape couvre une classe de régression différente.

## Ce que cette checklist ne remplace pas

Elle est un minimum avant release, pas un substitut à la définition de
"Done" par feature (`playtap-product`) qui s'applique en continu pendant
le développement.
