# PlayTap — Release Checklist

> Checklist complète et règles détaillées : skill **`playtap-release-gate`**
> — source de vérité unique, non dupliquée ici.

## Checklist (résumé opérationnel, cocher avant chaque release)

- [ ] `flutter analyze` — zéro erreur
- [ ] `flutter test` — tous les tests passent (y compris tests moteurs
      déterministes)
- [ ] Build natif Apple (app + watchOS) via XcodeBuildMCP
- [ ] Build natif Android + Wear OS
- [ ] Flows critiques testés via Mobile MCP (Score/Timer/Training/Custom,
      bout en bout)
- [ ] Audit permissions
- [ ] Audit privacy (cohérence offline-first)
- [ ] Audit dead buttons
- [ ] Audit crash (logs/crash reports vides sur les flows P0)
- [ ] Accessibility checks (watch UX + labels phone)
- [ ] Test offline (mode avion, flow complet)
- [ ] Test session recovery (kill process en session active, reprise
      correcte)

**Pas de release si un parcours P0 est cassé.**

Détail, justification et ordre recommandé de chaque étape :
`.claude/skills/playtap-release-gate/SKILL.md`.
