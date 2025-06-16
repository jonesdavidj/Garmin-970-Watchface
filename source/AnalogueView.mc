import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.ActivityMonitor;
import Toybox.UserProfile;
import Toybox.Math;

class AnalogView extends WatchUi.WatchFace {
    private var centerX as Number = 0;
    private var centerY as Number = 0;
    private var radius as Number = 0;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
        
        centerX = dc.getWidth() / 2;
        centerY = dc.getHeight() / 2;
        radius = Math.min(centerX, centerY) - 20;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        // Clear the screen with black background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Get current time
        var clockTime = System.getClockTime();
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_MEDIUM);
        
        // Draw main circle (watch rim)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawCircle(centerX, centerY, radius);
        
        // Draw hour markers in Tableau style
        drawHourMarkers(dc);
        
        // Draw hands
        drawHourHand(dc, clockTime.hour, clockTime.min);
        drawMinuteHand(dc, clockTime.min);
        drawSecondHand(dc, clockTime.sec);
        
        // Draw center dot
        dc.fillCircle(centerX, centerY, 6);
        
        // Draw data fields around the dial
        drawDataFields(dc, info);
    }
    
    private function drawHourMarkers(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        
        for (var i = 0; i < 12; i++) {
            var angle = (i * 30) - 90; // Start from 12 o'clock
            var angleRad = Math.toRadians(angle);
            
            var outerX = centerX + (radius - 5) * Math.cos(angleRad);
            var outerY = centerY + (radius - 5) * Math.sin(angleRad);
            var innerX = centerX + (radius - 15) * Math.cos(angleRad);
            var innerY = centerY + (radius - 15) * Math.sin(angleRad);
            
            // Make 12, 3, 6, 9 markers thicker
            if (i % 3 == 0) {
                dc.setPenWidth(4);
                innerX = centerX + (radius - 20) * Math.cos(angleRad);
                innerY = centerY + (radius - 20) * Math.sin(angleRad);
            } else {
                dc.setPenWidth(2);
            }
            
            dc.drawLine(outerX.toNumber(), outerY.toNumber(), innerX.toNumber(), innerY.toNumber());
        }
    }
    
    private function drawHourHand(dc as Graphics.Dc, hour as Number, minutes as Number) as Void {
        var angle = ((hour % 12) * 30) + (minutes * 0.5) - 90;
        var angleRad = Math.toRadians(angle);
        var handLength = radius * 0.5;
        
        var endX = centerX + handLength * Math.cos(angleRad);
        var endY = centerY + handLength * Math.sin(angleRad);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(4);
        dc.drawLine(centerX, centerY, endX.toNumber(), endY.toNumber());
    }
    
    private function drawMinuteHand(dc as Graphics.Dc, minutes as Number) as Void {
        var angle = (minutes * 6) - 90;
        var angleRad = Math.toRadians(angle);
        var handLength = radius * 0.7;
        
        var endX = centerX + handLength * Math.cos(angleRad);
        var endY = centerY + handLength * Math.sin(angleRad);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(centerX, centerY, endX.toNumber(), endY.toNumber());
    }
    
    private function drawSecondHand(dc as Graphics.Dc, seconds as Number) as Void {
        var angle = (seconds * 6) - 90;
        var angleRad = Math.toRadians(angle);
        var handLength = radius * 0.8;
        
        var endX = centerX + handLength * Math.cos(angleRad);
        var endY = centerY + handLength * Math.sin(angleRad);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(centerX, centerY, endX.toNumber(), endY.toNumber());
    }
    
    private function drawDataFields(dc as Graphics.Dc, info as Gregorian.Info) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        var activityInfo = ActivityMonitor.getInfo();
        var systemStats = System.getSystemStats();
        
        // Date (top)
        var dateStr = Lang.format("$1$/$2$", [info.day.format("%02d"), info.month.format("%02d")]);
        var dateY = centerY - radius + 25;
        drawTextCentered(dc, dateStr, centerX, dateY, Graphics.FONT_SYSTEM_SMALL);
        
        // Steps (top right)
        var stepsStr = formatNumber(activityInfo.steps) + " steps";
        var stepsX = centerX + radius * 0.7;
        var stepsY = centerY - radius * 0.4;
        drawTextCentered(dc, stepsStr, stepsX.toNumber(), stepsY.toNumber(), Graphics.FONT_SYSTEM_XTINY);
        
        // Heart Rate (right)
        var hrStr = "-- bpm";
        if (activityInfo has :currentHeartRate && activityInfo.currentHeartRate != null) {
            hrStr = activityInfo.currentHeartRate.toString() + " bpm";
        }
        var hrX = centerX + radius * 0.8;
        drawTextCentered(dc, hrStr, hrX.toNumber(), centerY, Graphics.FONT_SYSTEM_XTINY);
        
        // Body Battery (bottom right)
        var bbStr = "BB: --";
        if (systemStats has :battery && systemStats.battery != null) {
            bbStr = "BB: " + systemStats.battery.format("%.0f") + "%";
        }
        var bbX = centerX + radius * 0.7;
        var bbY = centerY + radius * 0.4;
        drawTextCentered(dc, bbStr, bbX.toNumber(), bbY.toNumber(), Graphics.FONT_SYSTEM_XTINY);
        
        // Battery indicator (left)
        var batteryStr = systemStats.battery.format("%.0f") + "%";
        var batteryX = centerX - radius * 0.8;
        drawTextCentered(dc, batteryStr, batteryX.toNumber(), centerY, Graphics.FONT_SYSTEM_XTINY);
        
        // Steps goal progress (bottom)
        var progressStr = "Goal: --";
        if (activityInfo has :stepGoal && activityInfo.stepGoal != null && activityInfo.stepGoal > 0) {
            var progress = (activityInfo.steps.toFloat() / activityInfo.stepGoal.toFloat() * 100).toNumber();
            progressStr = "Goal: " + progress.toString() + "%";
        }
        var progressY = centerY + radius - 25;
        drawTextCentered(dc, progressStr, centerX, progressY, Graphics.FONT_SYSTEM_XTINY);
    }
    
    private function drawTextCentered(dc as Graphics.Dc, text as String, x as Number, y as Number, font as Graphics.FontType) as Void {
        var textDimensions = dc.getTextDimensions(text, font);
        var textX = x - (textDimensions[0] / 2);
        var textY = y - (textDimensions[1] / 2);
        dc.drawText(textX, textY, font, text, Graphics.TEXT_JUSTIFY_LEFT);
    }
    
    private function formatNumber(number as Number or Null) as String {
        if (number == null) {
            return "--";
        }
        
        if (number >= 1000) {
            return (number.toFloat() / 1000.0).format("%.1f") + "k";
        }
        return number.toString();
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
    }
}