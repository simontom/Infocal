using Toybox.WatchUi as Ui;
using DataProvider as DP;
using RuntimeData as RD;
using Toybox.Math as M;

class MoonPhaseDrawable extends Ui.Drawable {

    hidden var centerX;
    hidden var centerY;
    hidden var radius;

    private var clipSize;
    private var clipX;
    private var clipY;

    private var moonPhaseProvider;
    private var currentMoonIluminatedPhase;

    function initialize(params) {
        Drawable.initialize(params);

        calculateDimensions(params);
        moonPhaseProvider = new DP.MoonPhaseDataProvider();
    }

    function draw(dc) {
        var moonIluminatedPhase = moonPhaseProvider.calculateMoonPhase();
        if (RD.forceRenderComponent || (currentMoonIluminatedPhase != moonIluminatedPhase)) {
            drawMoon(dc, moonIluminatedPhase);
        }
    }

    private function drawMoon(dc, phase) {
        var moonIluminationColor = getMoonIluminationColor(phase);

        // Clear and draw dark backfround of the Moon
        dc.setClip(clipX, clipY, clipSize, clipSize);
        dc.setColor(Graphics.COLOR_DK_GRAY, gbackground_color);
        dc.clear();
        dc.fillCircle(centerX, centerY, radius);

        // Set proper color to draw the iluminated part of the moon
        dc.setColor(moonIluminationColor, Graphics.COLOR_TRANSPARENT);

        for (var yPos = 0; yPos <= radius; yPos++) {
            var xPos = M.sqrt(radius*radius - yPos*yPos).toNumber();

            // Determine the edges of the iluminated part of the moon
            var rPos = 2 * xPos;
            var xPos1, xPos2;
            if (phase < 0.5) {
                xPos1 = - xPos;
                xPos2 = (rPos - 2*phase*rPos - xPos).toNumber();
            } else {
                xPos1 = xPos;
                xPos2 = (xPos - 2*phase*rPos + rPos).toNumber();
            }

            // Draw the iluminated part of the moon
            dc.drawLine(
                centerX + xPos1, centerY - yPos,
                centerX + xPos2, centerY - yPos); // Draws iluminated TOP half
            dc.drawLine(
                centerX + xPos1, centerY + yPos,
                centerX + xPos2, centerY + yPos); // Draws iluminated BOTTOM half
        }

        dc.clearClip();
    }

    // TODO: Play a bit with constants to meet the best feel from used colors
    private function getMoonIluminationColor(phase) {
        if ((phase > 0.85) || (phase < 0.125)) {
            return Graphics.COLOR_YELLOW;
        }

        if ((phase >= 0.125) && (phase < 0.36)) {
            return Graphics.COLOR_ORANGE;
        }

        if ((phase >= 0.645) && (phase <= 0.85)) {
            return Graphics.COLOR_ORANGE;
        }

        return Graphics.COLOR_LT_GRAY;
    }

    private function calculateDimensions(params) {
        centerX = params.get(:centerX);
        centerY = params.get(:centerY);
        radius = params.get(:radius);

        // Try to resize and reposition to keep the whole Moon inside the dc.clip
        clipSize = 2 * radius + 2;
        clipX = centerX - radius - 1;
        clipY = centerY - radius - 1;
    }
}
