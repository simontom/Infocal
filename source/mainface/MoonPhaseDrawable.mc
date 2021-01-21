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
        if ((currentMoonIluminatedPhase != moonIluminatedPhase) || RD.forceRenderComponent) {
            // dc.setClip(xTopLeft, yTopLeft, size+1, size+1);
            // dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            // dc.clear();

            // // dc.setColor(gmain_color, Graphics.COLOR_TRANSPARENT);
            // // if (Time.now().value() % 3 == 0) {
            //     dc.fillCircle(x, y, radius);
            // // }
            // dc.clearClip();

            drawMoon(dc, moonIluminatedPhase);
        }
    }

    // TODO: Fix size and position
    function drawMoon(dc, phase) {
        var moonIluminationColor = getMoonIluminationColor(phase);

        // Draw darkness part of the moon
        // dc.setClip(clipX, clipY, clipSize, clipSize);
        // dc.clear();
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
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

            // Toybox.System.println(
            //     Toybox.Lang.format(
            //         "yPos:$1$ xPos:$2$ rPos:$3$ xPos1:$4$ xPos2:$5$",
            //         [yPos, xPos, rPos, xPos1, xPos2]
            //     )
            // );

            // Draw the iluminated part of the moon
            dc.drawLine(
                centerX + xPos1, centerY - yPos,
                centerX + xPos2, centerY - yPos); // Draws iluminated TOP half
            dc.drawLine(
                centerX + xPos1, centerY + yPos,
                centerX + xPos2, centerY + yPos); // Draws iluminated BOTTOM half
        }

        // Toybox.System.println("");
        // Toybox.System.println("");

        // dc.clearClip();
    }

    private function getMoonIluminationColor(phase) {
        if ((phase > 0.85) || (phase < 0.125)) {
            return Graphics.COLOR_YELLOW;
        }

        if ((phase >= 0.125) && (phase < 0.31)) {
            return Graphics.COLOR_ORANGE;
        }

        if ((phase >= 0.665) && (phase <= 0.85)) {
            return Graphics.COLOR_ORANGE;
        }

        return Graphics.COLOR_LT_GRAY;
    }

    private function calculateDimensions(params) {
        centerX = params.get(:centerX);
        centerY = params.get(:centerY);
        radius = params.get(:radius);

        clipSize = 2 * radius + 1;
        clipX = centerX - radius;
        clipY = centerY - radius;
    }
}
