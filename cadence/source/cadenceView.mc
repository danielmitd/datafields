using Toybox.Graphics;
using Toybox.Application;

class cadenceView extends Toybox.WatchUi.DataField {

    protected var currentCadence;
    protected var averageCadence;
    protected var personalCadence;
    protected var themedItems;

    enum {
        THEME_NONE,
        THEME_RED,
        THEME_RED_INVERT,
        INDICATE_HIGH,
        INDICATE_LOW,
        INDICATE_NORMAL,
    }

    enum {
        MODE_AVERAGE,
        MODE_PERSONAL,
    }

    function initialize() {
        DataField.initialize();
        currentCadence = null;
        averageCadence = 0;
    }

    function onLayout(dc) {
        var fullWidth = dc.getWidth() > 122;

        if (fullWidth) {
            View.setLayout(Rez.Layouts.FullWidthLayout(dc));
        } else {
            View.setLayout(Rez.Layouts.HalfWidthLayout(dc));
        }

        themedItems = {
            :cadence => View.findDrawableById("cadence"),
            :average => View.findDrawableById("average"),
            :metric  => View.findDrawableById("metric"),
            :metric2  => View.findDrawableById("metric2"),
            :label  => View.findDrawableById("label"),
            :title   => View.findDrawableById("title")
        };

        themedItems[:title].setText(Rez.Strings.title);
        themedItems[:metric].setText(Rez.Strings.metric);

        // only available on full width
        if (fullWidth) {
            var mode = Application.Properties.getValue("cadenceMode");
            themedItems[:label].setText(mode == MODE_AVERAGE ? Rez.Strings.labelAvg : Rez.Strings.labelPersonal);
            themedItems[:metric2].setText(Rez.Strings.metric);

            // adjust the label and metrics in height
            var fontSize = Graphics.getFontHeight(Graphics.Graphics.FONT_NUMBER_MILD);
            themedItems[:metric].locY = themedItems[:cadence].locY + (fontSize/2) - 2;
            themedItems[:metric2].locY = themedItems[:metric].locY;

        }
        return true;
    }

    function compute(info) {
        if(info has :currentCadence){
            currentCadence = info.currentCadence;
        }

        if (info has :averageCadence) {
            if (info.averageCadence != null) {
                averageCadence = info.averageCadence;
            } else {
                averageCadence = 0;
            }
        }
    }

    /**
     * render colors for items based on theme and indication.
     *
     * @return themed colors
     */
    function themed(itemsDict, indication) {
        var theme = Application.Properties.getValue("theme");
        var backgroundColor = getBackgroundColor();
        var defaultColor = backgroundColor == Graphics.COLOR_BLACK ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        var items = itemsDict.values();
        var itemCount = itemsDict.size();
        var color = defaultColor;

        switch (theme) {
            case THEME_RED:
                for (var i = 0; i < itemCount; i++ ) {
                    // implicit: only make first item red/green
                    var item = items[i];
                    if (null == item) {
                        continue;
                    }

                    var indicate = item == themedItems[:cadence];
                    if (indicate && indication == INDICATE_HIGH) {
                        color = Graphics.COLOR_DK_GREEN;
                        item.setColor(Graphics.COLOR_DK_GREEN);
                    } else if (indicate && indication == INDICATE_LOW) {
                        color = Graphics.COLOR_DK_RED;
                        item.setColor(Graphics.COLOR_DK_RED);
                    } else {
                        // others get default coloring
                        item.setColor(defaultColor);
                    }
                }
                break;

            case THEME_RED_INVERT:
                for (var j = 0; j < itemCount; j++ ) {
                    // explicit: make all items red/green/default
                    var item = items[j];
                    if (null == item) {
                        continue;
                    }

                    if (indication == INDICATE_HIGH) {
                        color = Graphics.COLOR_WHITE;
                        item.setColor(Graphics.COLOR_WHITE);
                        backgroundColor = Graphics.COLOR_DK_GREEN;
                    } else if (indication == INDICATE_LOW) {
                        color = Graphics.COLOR_WHITE;
                        item.setColor(Graphics.COLOR_WHITE);
                        backgroundColor = Graphics.COLOR_DK_RED;
                    } else {
                        item.setColor(defaultColor);
                    }
                }
                break;

            default:
            case THEME_NONE:
                // all get default coloring
                for (var k = 0; k < itemCount; k++ ) {
                    if (null != items[k]) {
                        items[k].setColor(defaultColor);
                    }
                }
                break;
        }

        return {
            :background => backgroundColor,
            :color => color,
            :indication => indication
        };
    }

    function getComparableCadence() {
        var mode = Application.Properties.getValue("cadenceMode");

        if (mode == MODE_PERSONAL) {
            return Application.Properties.getValue("personalCadence");
        }

        return averageCadence;
    }

    function getVariations() {
        var threshold = Application.Properties.getValue("threshold").toFloat();
        var compareable = getComparableCadence();
        var control = compareable * (threshold/100);

        return {
            :min => compareable - control,
            :max => compareable + control
        };
    }

    function drawArrows(dc, colors) {
        var center = dc.getWidth() / 2;
        var vcenter = (dc.getHeight() / 2) + 4;

        // up arrow, 13x7
        dc.setColor(colors[:indication] == INDICATE_HIGH ? colors[:color] : Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[center - 6, vcenter + 6], [center, vcenter], [center + 6, vcenter + 6]]);

        // down arrow, 13x7
        dc.setColor(colors[:indication] == INDICATE_LOW ? colors[:color] : Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[center - 6, vcenter + 10], [center, vcenter + 16], [center + 6, vcenter + 10]]);
    }

    function onUpdate(dc) {
        var colors = {
            :background => getBackgroundColor(),
            :color => null
        };
        var background = View.findDrawableById("Background");
        var fullWidth = dc.getWidth() > 122;

        if (currentCadence != null) {
            var variations = getVariations();

            if (currentCadence > variations[:max]) {
                colors = themed(themedItems, INDICATE_HIGH);
            } else if (currentCadence < variations[:min]) {
                colors = themed(themedItems, INDICATE_LOW);
            } else {
                colors = themed(themedItems, INDICATE_NORMAL);
            }

            themedItems[:cadence].setText(currentCadence.format("%d"));
        } else {
            // not initialized yet
            colors = themed(themedItems, INDICATE_NORMAL);
            themedItems[:cadence].setText("0");
        }

        background.setColor(colors[:background]);
        themedItems[:average].setText(getComparableCadence().format("%d"));
        View.onUpdate(dc);

        if (!fullWidth) {
            return;
        }

        drawArrows(dc, colors);
    }

}
