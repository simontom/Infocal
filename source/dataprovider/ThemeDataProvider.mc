using SettingsEnums as SE;
using Toybox.Application;

module DataProvider {

    class ThemeDataProvider {

        var smallDigitalFont = null;
        var second_digi_font = null;
        var second_x = 160;
        var second_y = 140;

        var second_font_height_half = 7;
        var second_clip_size = null;

        // Parsed theme
        private var last_theme_code = null;
        var gbackground_color = 0x000000;
        var gmain_color = 0xFFFFFF;
        var gsecondary_color = 0xFF0000;
        var garc_color = 0x555555;
        var gbar_color_indi = 0xAAAAAA;
        var gbar_color_back = 0x550000;
        var gbar_color_0 = 0xFFFF00;
        var gbar_color_1 = 0x0000FF;

        function initialize() {
            reloadSettings();
        }

        function reloadSettings() {
            if (smallDigitalFont == null) {
                smallDigitalFont = WatchUi.loadResource(Rez.Fonts.smadigi);
            }

            loadTheme();
            loadAlwaysOnStyle();
        }

        private function loadTheme() {
            var theme_code = Application.getApp().getProperty("theme_code");

            if (last_theme_code == null || last_theme_code != theme_code) {
                var theme_pallete = WatchUi.loadResource(Rez.JsonData.theme_pallete);
                var theme = theme_pallete["" + theme_code];

                gbackground_color = theme[0];
                gmain_color = theme[1];
                gsecondary_color = theme[2];
                garc_color = theme[3];
                gbar_color_indi = theme[4];
                gbar_color_back = theme[5];
                gbar_color_0 = theme[6];
                gbar_color_1 = theme[7];
            }
        }

        private function loadAlwaysOnStyle() {
            var always_on_second = Application.getApp().getProperty("always_on_second");

            // If there is no Always On enabled there is no need to keep this in memory
            if (!always_on_second) {
                second_digi_font = null;
                // second_font_height_half = null;
                second_clip_size = null;

                return;
            }

            var always_on_style = Application.getApp().getProperty("always_on_style");

            if (always_on_style == SE.ALWAYS_ON_STYLE_SMALL) {
                second_digi_font = WatchUi.loadResource(Rez.Fonts.secodigi);
                second_font_height_half = 7;
                second_clip_size = [20, 15];
            } else {
                second_digi_font = WatchUi.loadResource(Rez.Fonts.xsecodigi);
                second_font_height_half = 14;
                second_clip_size = [26, 22];
            }
        }
    }

}
