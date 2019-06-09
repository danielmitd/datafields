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
        View.setLayout(Rez.Layouts.MainLayout(dc));
        themedItems = {
            :cadence => View.findDrawableById("cadence"),
            :average => View.findDrawableById("average"),
            :metric  => View.findDrawableById("metric"),
            :title   => View.findDrawableById("title")
        };

        themedItems[:title].locY -= 14;

        themedItems[:cadence].locX += 16;
        themedItems[:cadence].locY += 15;

        themedItems[:average].locX += 20;
        themedItems[:average].locY += 7;

        themedItems[:metric].locX += 20;
        themedItems[:metric].locY += 18;

        themedItems[:title].setText(Rez.Strings.title);
        themedItems[:metric].setText(Rez.Strings.metric);
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
     * @return new background color
     */
    function setThemedColors(itemsDict, indication) {
        var theme = Application.Properties.getValue("theme");
        var backgroundColor = getBackgroundColor();
        var defaultColor = backgroundColor == Graphics.COLOR_BLACK ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        var items = itemsDict.values();
        var itemCount = itemsDict.size();

        switch (theme) {
            case THEME_RED:
                for (var i = 0; i < itemCount; i++ ) {
                    // implicit: only make first item red/green
                    var indicate = items[i] == themedItems[:cadence];
                    if (indicate && indication == INDICATE_HIGH) {
                        items[i].setColor(Graphics.COLOR_DK_GREEN);
                    } else if (indicate && indication == INDICATE_LOW) {
                        items[i].setColor(Graphics.COLOR_DK_RED);
                    } else {
                        // others get default coloring
                        items[i].setColor(defaultColor);
                    }
                }
                break;

            case THEME_RED_INVERT:
                for (var j = 0; j < itemCount; j++ ) {
                    // explicit: make all items red/green/default
                    if (indication == INDICATE_HIGH) {
                        items[j].setColor(Graphics.COLOR_WHITE);
                        backgroundColor = Graphics.COLOR_DK_GREEN;
                    } else if (indication == INDICATE_LOW) {
                        items[j].setColor(Graphics.COLOR_WHITE);
                        backgroundColor = Graphics.COLOR_DK_RED;
                    } else {
                        items[j].setColor(defaultColor);
                    }
                }
                break;

            default:
            case THEME_NONE:
                // all get default coloring
                for (var k = 0; k < itemCount; k++ ) {
                    items[k].setColor(defaultColor);
                }
                break;
        }

        return backgroundColor;
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

    function onUpdate(dc) {
        var backgroundColor = getBackgroundColor();
        var background = View.findDrawableById("Background");

        if (currentCadence != null) {
            var variations = getVariations();

            if (currentCadence > variations[:max]) {
                backgroundColor = setThemedColors(themedItems, INDICATE_HIGH);
            } else if (currentCadence < variations[:min]) {
                backgroundColor = setThemedColors(themedItems, INDICATE_LOW);
            } else {
                backgroundColor = setThemedColors(themedItems, INDICATE_NORMAL);
            }

            themedItems[:cadence].setText(currentCadence.format("%d"));
        } else {
            // not initialized yet
            setThemedColors(themedItems, INDICATE_NORMAL);
            themedItems[:cadence].setText("0");
        }

        background.setColor(backgroundColor);
        themedItems[:average].setText(getComparableCadence().format("%d"));

        View.onUpdate(dc);
    }

}
