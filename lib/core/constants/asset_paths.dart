enum MascotState { welcome, empty, search, success, error, loading }

enum BackgroundStyle { homeBanner, emptyState, headerPattern }

abstract final class AssetPaths {
  static const brandMark = 'assets/mascots/brand_mark.svg';
  static const mascots = {
    MascotState.welcome: 'assets/mascots/mascot_welcome.svg',
    MascotState.empty: 'assets/mascots/mascot_empty.svg',
    MascotState.search: 'assets/mascots/mascot_search.svg',
    MascotState.success: 'assets/mascots/mascot_success.svg',
    MascotState.error: 'assets/mascots/mascot_error.svg',
    MascotState.loading: 'assets/mascots/mascot_loading.svg',
  };
  static const backgrounds = {
    BackgroundStyle.homeBanner: 'assets/backgrounds/home_banner.svg',
    BackgroundStyle.emptyState: 'assets/backgrounds/empty_state.svg',
    BackgroundStyle.headerPattern: 'assets/backgrounds/header_pattern.svg',
  };
}
