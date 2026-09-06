// Firefox prefs for the Catppuccin light/dark switcher.
// Installed into the active profile by ~/dotfiles/firefox/install.sh.
// user.js is re-applied on every Firefox start, so these survive restarts.

// Let userChrome.css load (required for the Catppuccin chrome colors).
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Websites follow the browser theme, which follows the OS via xdg-desktop-portal.
// 0 = force dark, 1 = force light, 2 = follow. Must be 2 for `theme` to work.
user_pref("layout.css.prefers-color-scheme.content-override", 2);
