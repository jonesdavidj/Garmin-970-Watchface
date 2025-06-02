class App extends WatchFace {

    function initialize() {
        WatchFace.initialize();
    }

    function onUpdate(dc) {
        var currentTime = System.getClockTime();
        dc.clear();
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2,
                     Graphics.FONT_XLARGE,
                     currentTime.hour + ":" + (currentTime.min < 10 ? "0" : "") + currentTime.min);
    }
}
