// AISRI Zone Monitor - Data Field Implementation
// Real-time heart rate zone guidance for Garmin devices
// Version: 1.0.0
// Author: AKURA SafeStride Team
// License: MIT

using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Activity as Act;
using Toybox.UserProfile as UserProfile;
using Toybox.Lang;
using Toybox.System as Sys;
using Toybox.Lang as Lang;

// Main Data Field class
class AISRIZoneView extends Ui.DataField {

    // Private variables
    hidden var currentZone;
    hidden var maxHR;
    hidden var currentHR;
    hidden var timeInZone;
    hidden var previousZone;

    // AISRI Zone Constants (based on % of max HR)
    const ZONE_AR = 0;   // Active Recovery: 50-60%
    const ZONE_F = 1;    // Foundation: 60-70%
    const ZONE_EN = 2;   // Endurance: 70-80%
    const ZONE_TH = 3;   // Threshold: 80-87%
    const ZONE_P = 4;    // Peak: 87-95%
    const ZONE_SP = 5;   // Sprint: 95-100%

    // Initialize the data field
    function initialize() {
        DataField.initialize();
        
        currentZone = ZONE_AR;
        previousZone = ZONE_AR;
        currentHR = 0;
        timeInZone = 0;
        
        // Calculate max HR using AISRI formula: 208 - (0.7 × age)
        var profile = UserProfile.getProfile();
        var age = 35; // Default age
        
        // Try to get age from profile (may not be available on all devices)
        if (profile != null) {
            try {
                var birthYear = profile.birthYear;
                if (birthYear != null) {
                    var currentYear = 2026; // Will use system time in production
                    age = currentYear - birthYear;
                }
            } catch (ex) {
                // Age not available, use default
            }
        }
        
        maxHR = 208 - (0.7 * age);
        
        // Debug output
        Sys.println("AISRI Zone Monitor initialized");
        Sys.println("Age: " + age + ", Max HR: " + maxHR.format("%.0f"));
    }

    // Called every second during activity
    // This is where we read heart rate and calculate zone
    function compute(info as Act.Info) as Void {
        // Get current heart rate from activity info
        if (info has :currentHeartRate && info.currentHeartRate != null) {
            currentHR = info.currentHeartRate;
            
            // Calculate which zone we're in
            var newZone = calculateZone(currentHR, maxHR);
            
            // If zone changed, reset time counter
            if (newZone != currentZone) {
                previousZone = currentZone;
                currentZone = newZone;
                timeInZone = 0;
                
                Sys.println("Zone changed: " + getZoneName(previousZone) + " -> " + getZoneName(currentZone));
            } else {
                timeInZone++;
            }
        } else {
            // No heart rate detected
            currentHR = 0;
            Sys.println("No HR data available");
        }
    }

    // Calculate AISRI zone from heart rate
    // Returns zone number (0-5)
    function calculateZone(hr as Lang.Number, maxHr as Lang.Float) as Lang.Number {
        if (hr <= 0 || maxHr <= 0) {
            return ZONE_AR; // Default to recovery if no data
        }
        
        // Calculate percentage of max HR
        var hrPercent = (hr.toFloat() / maxHr) * 100.0;
        
        // Determine zone based on AISRI methodology
        if (hrPercent >= 95.0) {
            return ZONE_SP; // Sprint: 95-100%
        } else if (hrPercent >= 87.0) {
            return ZONE_P;  // Peak: 87-95%
        } else if (hrPercent >= 80.0) {
            return ZONE_TH; // Threshold: 80-87%
        } else if (hrPercent >= 70.0) {
            return ZONE_EN; // Endurance: 70-80%
        } else if (hrPercent >= 60.0) {
            return ZONE_F;  // Foundation: 60-70%
        } else {
            return ZONE_AR; // Active Recovery: 50-60%
        }
    }

    // Get zone name as string
    function getZoneName(zone as Lang.Number) as Lang.String {
        if (zone == ZONE_SP) { return "SPRINT"; }
        if (zone == ZONE_P)  { return "PEAK"; }
        if (zone == ZONE_TH) { return "THRESHOLD"; }
        if (zone == ZONE_EN) { return "ENDURANCE"; }
        if (zone == ZONE_F)  { return "FOUNDATION"; }
        return "RECOVERY";
    }

    // Get zone abbreviation (for small screens)
    function getZoneAbbrev(zone as Lang.Number) as Lang.String {
        if (zone == ZONE_SP) { return "SP"; }
        if (zone == ZONE_P)  { return "P"; }
        if (zone == ZONE_TH) { return "TH"; }
        if (zone == ZONE_EN) { return "EN"; }
        if (zone == ZONE_F)  { return "F"; }
        return "AR";
    }

    // Get color for zone (color-coded by intensity)
    function getZoneColor(zone as Lang.Number) as Lang.Number {
        if (zone == ZONE_SP) { return Gfx.COLOR_RED; }        // Sprint - Red
        if (zone == ZONE_P)  { return Gfx.COLOR_ORANGE; }     // Peak - Orange
        if (zone == ZONE_TH) { return Gfx.COLOR_YELLOW; }     // Threshold - Yellow
        if (zone == ZONE_EN) { return Gfx.COLOR_BLUE; }       // Endurance - Blue
        if (zone == ZONE_F)  { return Gfx.COLOR_DK_BLUE; }    // Foundation - Dark Blue
        return Gfx.COLOR_GREEN;                               // Recovery - Green
    }

    // Display the data field on screen
    // This is called every time the screen needs to refresh
    function onUpdate(dc as Gfx.Dc) as Void {
        // Set background color
        dc.setColor(Gfx.COLOR_TRANSPARENT, Gfx.COLOR_BLACK);
        dc.clear();

        // Get screen dimensions
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        // Get zone info
        var zoneName = getZoneName(currentZone);
        var zoneColor = getZoneColor(currentZone);

        // Check if we have enough space for full layout
        var isLargeScreen = (width > 200 && height > 200);

        if (isLargeScreen) {
            // Large screen layout (Fenix 7, FR 955, etc.)
            drawLargeLayout(dc, width, height, zoneName, zoneColor);
        } else {
            // Small screen layout (FR 245, Vivoactive, etc.)
            drawCompactLayout(dc, width, height, zoneName, zoneColor);
        }
    }

    // Draw layout for large screens (200x200+)
    function drawLargeLayout(dc as Gfx.Dc, width as Lang.Number, height as Lang.Number, zoneName as Lang.String, zoneColor as Lang.Number) as Void {
        // Draw zone name at top (in zone color)
        dc.setColor(zoneColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2,
            height * 0.28,
            Gfx.FONT_MEDIUM,
            zoneName,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );

        // Draw heart rate in center (large, white)
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        var hrText = currentHR > 0 ? currentHR.format("%d") : "--";
        dc.drawText(
            width / 2,
            height * 0.50,
            Gfx.FONT_NUMBER_MEDIUM,
            hrText,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );

        // Draw "bpm" label below HR (small, gray)
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2,
            height * 0.65,
            Gfx.FONT_TINY,
            "bpm",
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );

        // Draw time in zone at bottom (gray)
        if (timeInZone > 0) {
            var minutes = timeInZone / 60;
            var seconds = timeInZone % 60;
            var timeText = minutes.format("%02d") + ":" + seconds.format("%02d");
            
            dc.drawText(
                width / 2,
                height * 0.85,
                Gfx.FONT_TINY,
                timeText,
                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
            );
        }
    }

    // Draw layout for compact screens (<200x200)
    function drawCompactLayout(dc as Gfx.Dc, width as Lang.Number, height as Lang.Number, zoneName as Lang.String, zoneColor as Lang.Number) as Void {
        // Use abbreviation for zone name
        var zoneAbbrev = getZoneAbbrev(currentZone);
        
        // Draw zone abbreviation (colored)
        dc.setColor(zoneColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2,
            height * 0.30,
            Gfx.FONT_SMALL,
            zoneAbbrev,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );

        // Draw heart rate (large, white)
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        var hrText = currentHR > 0 ? currentHR.format("%d") : "--";
        dc.drawText(
            width / 2,
            height * 0.60,
            Gfx.FONT_LARGE,
            hrText,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );

        // Draw "bpm" label (small)
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2,
            height * 0.80,
            Gfx.FONT_XTINY,
            "bpm",
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );
    }

    // Optional: Get label for data field (shown in activity settings)
    function getLabel() as Lang.String {
        return "AISRI Zone";
    }
}

// App entry point
using Toybox.Application;

class AISRIZoneApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [ new AISRIZoneView() ];
    }
}

// Create the app instance
function getApp() as AISRIZoneApp {
    return Application.getApp() as AISRIZoneApp;
}
