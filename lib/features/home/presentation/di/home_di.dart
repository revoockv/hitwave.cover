/// Registers the home feature: nothing — the home page: it composes the other features (songs, covers, practice, history, tuner, settings, lyrics) and owns no data.
///
/// Kept so every feature has the same shape; call it from `registerAndInit()` when the feature gets a data source.
void registerAndInitHome() {}
