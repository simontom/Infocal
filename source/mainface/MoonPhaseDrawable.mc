using Toybox.WatchUi as Ui;
using DataProvider as DP;
using RuntimeData as RD;
using Toybox.Math as M;

class MoonPhaseDrawable extends Ui.Drawable {

    hidden var x;
    hidden var y;
    hidden var radius;

    private var size;
    private var xTopLeft;
    private var yTopLeft;

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

            // dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            // dc.fillEllipse(x, y, 5, radius);

            // dc.clearClip();

            drawMoon(dc, moonIluminatedPhase);
        }
    }

    // TODO: Fix size and position
    private function drawMoon(dc, phase) {
        // dc.setClip(xTopLeft, yTopLeft, size+1, size+1);

        var moonIluminationColor = getMoonIluminationColor(phase);

        for (var yPos = 0; yPos <= 45; yPos++) {
            var xPos = M.sqrt(45*45 - yPos*yPos).toNumber();

            // Draw darkness part of the moon
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(90-xPos, yPos+90, xPos+90, yPos+90);
            dc.drawLine(90-xPos, 90-yPos, xPos+90, 90-yPos);

            // Determine the edges of the lighted part of the moon
            var rPos = 2 * xPos;
            var xPos1, xPos2;
            if (phase < 0.5) {
                xPos1 = - xPos;
                xPos2 = (rPos - 2*phase*rPos - xPos).toNumber();
            } else {
                xPos1 = xPos;
                xPos2 = (xPos - 2*phase*rPos + rPos).toNumber();
            }

            // Draw the lighted part of the moon
            // dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            // dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            // dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);

            dc.setColor(moonIluminationColor, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(xPos1+90, 90-yPos, xPos2+90, 90-yPos);
            dc.drawLine(xPos1+90, yPos+90, xPos2+90, yPos+90);
        }

        // dc.clearClip();
    }

    private function getMoonIluminationColor(phase) {
        Toybox.System.println(phase);

        if ((phase > 0.85) || (phase < 0.125)) {
            return Graphics.COLOR_YELLOW;
        }

        if (((phase >= 0.125) && (phase < 0.31)) || ((phase >= 0.665) && (phase <= 0.85))) {
            return Graphics.COLOR_ORANGE;
        }

        return Graphics.COLOR_LT_GRAY;
    }

    private function calculateDimensions(params) {
        x = params.get(:x);
        y = params.get(:y);
        radius = params.get(:radius);

        size = 2 * radius;
        xTopLeft = x - radius;
        yTopLeft = y - radius;

        System.println("x:"+x + " y:"+y + " r:"+radius + " s:"+size + " xT:"+xTopLeft + " yT:"+yTopLeft);
    }
}
