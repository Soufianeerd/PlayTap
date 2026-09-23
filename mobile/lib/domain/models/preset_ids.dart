/// Stable, sport-agnostic preset identifiers shared across layers (data
/// seed, session creation, history/routing lookups) — see CLAUDE.md step 8
/// ("IDs stables: sport.petanque") and docs/DATA_MODEL.md. Never a
/// translated display string: visible names always resolve via
/// localization keys (e.g. `l10n.presetPetanque`), never this id.
library;

const petanquePresetRef = 'sport.petanque';
const basketballPresetRef = 'sport.basketball';
const footballPresetRef = 'sport.football';
const futsalPresetRef = 'sport.futsal';
const tennisPresetRef = 'sport.tennis';
