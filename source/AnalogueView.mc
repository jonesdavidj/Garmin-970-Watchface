using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.ActivityMonitor;
using Toybox.UserProfile;

class AnalogView extends WatchUi.WatchFace {
    var centerX, centerY, radius;
    var font;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.WatchFace(dc));
        
        centerX = dc.getWidth() / 2;
        centerY = dc.getHeight() / 2;
        radius = Math.min(centerX, centerY) - 20;
        
        font = Graphics.FONT_SYSTEM_TINY;
    }

    function onUpdate(dc) {
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
    
    function drawHourMarkers(dc) {
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
            
            dc.drawLine(outerX, outerY, innerX, innerY);
        }
    }
    
    function drawHourHand(dc, hour, minutes) {
        var angle = ((hour % 12) * 30) + (minutes * 0.5) - 90;
        var angleRad = Math.toRadians(angle);
        var handLength = radius * 0.5;
        
        var endX = centerX + handLength * Math.cos(angleRad);
        var endY = centerY + handLength * Math.sin(angleRad);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(4);
        dc.drawLine(centerX, centerY, endX, endY);
    }
    
    function drawMinuteHand(dc, minutes) {
        var angle = (minutes * 6) - 90;
        var angleRad = Math.toRadians(angle);
        var handLength = radius * 0.7;
        
        var endX = centerX + handLength * Math.cos(angleRad);
        var endY = centerY + handLength * Math.sin(angleRad);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(centerX, centerY, endX, endY);
    }
    
    function drawSecondHand(dc, seconds) {
        var angle = (seconds * 6) - 90;
        var angleRad = Math.toRadians(angle);
        var handLength = radius * 0.8;
        
        var endX = centerX + handLength * Math.cos(angleRad);
        var endY = centerY + handLength * Math.sin(angleRad);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(centerX, centerY, endX, endY);
    }
    
    function drawDataFields(dc, info) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        var activityInfo = ActivityMonitor.getInfo();
        var profile = UserProfile.getProfile();
        var systemStats = System.getSystemStats();
        
        // Date (top)
        var dateStr = info.day.format("%02d") + "/" + info.month.format("%02d");
        var dateY = centerY - radius + 25;
        drawTextCentered(dc, dateStr, centerX, dateY, Graphics.FONT_SYSTEM_SMALL);
        
        // Steps (top right)
        var stepsStr = formatNumber(activityInfo.steps) + " steps";
        var stepsX = centerX + radius * 0.7;
        var stepsY = centerY - radius * 0.4;
        drawTextCentered(dc, stepsStr, stepsX, stepsY, Graphics.FONT_SYSTEM_XTINY);
        
        // Heart Rate (right)
        var hrStr = "-- bpm";
        if (activityInfo has :currentHeartRate && activityInfo.currentHeartRate != null) {
            hrStr = activityInfo.currentHeartRate.toString() + " bpm";
        }
        var hrX = centerX + radius * 0.8;
        drawTextCentered(dc, hrStr, hrX, centerY, Graphics.FONT_SYSTEM_XTINY);
        
        // Body Battery (bottom right)
        var bbStr = "BB: --";
        if (systemStats has :battery && systemStats.battery != null) {
            bbStr = "BB: " + systemStats.battery.format("%.0f") + "%";
        }
        var bbX = centerX + radius * 0.7;
        var bbY = centerY + radius * 0.4;
        drawTextCentered(dc, bbStr, bbX, bbY, Graphics.FONT_SYSTEM_XTINY);
        
        // Exercise Readiness (bottom)
        var erStr = "Ready: --";
        // Note: Exercise readiness requires specific API access
        var erY = centerY + radius - 25;
        drawTextCentered(dc, erStr, centerX, erY, Graphics.FONT_SYSTEM_XTINY);
        
        // VO2 Max (bottom left)
        var vo2Str = "VO2: --";
        if (profile has :vo2maxRunning && profile.vo2maxRunning != null) {
            vo2Str = "VO2: " + profile.vo2maxRunning.toString();
        }
        var vo2X = centerX - radius * 0.7;
        var vo2Y = centerY + radius * 0.4;
        drawTextCentered(dc, vo2Str, vo2X, vo2Y, Graphics.FONT_SYSTEM_XTINY);
        
        // Battery indicator (left)
        var batteryStr = systemStats.battery.format("%.0f") + "%";
        var batteryX = centerX - radius * 0.8;
        drawTextCentered(dc, batteryStr, batteryX, centerY, Graphics.FONT_SYSTEM_XTINY);
    }
    
    function drawTextCentered(dc, text, x, y, font) {
        var textDimensions = dc.getTextDimensions(text, font);
        var textX = x - (textDimensions[0] / 2);
        var textY = y - (textDimensions[1] / 2);
        dc.drawText(textX, textY, font, text, Graphics.TEXT_JUSTIFY_LEFT);
    }
    
    function formatNumber(number) {
        if (number == null) {
            return "--";
        }
        
        if (number >= 1000) {
            return (number / 1000.0).format("%.1f") + "k";
        }
        return number.toString();
    }

    function onHide() {
    }

    function onExitSleep() {
    }

    function onEnterSleep() {
    }
}