# Teszt: kontroller-rezgés (Rumble): egy hamis, rezegni tudó kontroller (navigator.getGamepads felülírva) naplózza a playEffect-hívásokat;
# sérülés / landolás / menü-hang után a megfelelő rezgés jön (vagy nem), a VIBRATION kikapcsolva semmi, a szünet leállítja (reset).
param([string]$Base = "http://127.0.0.1:3220/", [string]$Out = "$PSScriptRoot/out")
. "$PSScriptRoot/cdp-lib.ps1"
try {
    Start-Cdp ($Base + "?level=0") $Out
    Start-Sleep -Seconds 8
    Js @"
(function(){
  window.__rumble = [];
  var act = { playEffect: function(t, o){ window.__rumble.push({t:t, d:o.duration, s:Math.round(o.strongMagnitude*100), w:Math.round(o.weakMagnitude*100)}); return Promise.resolve('complete'); },
              reset: function(){ window.__rumble.push({t:'reset'}); return Promise.resolve('complete'); } };
  var pad = { id:'Fake DualShock 4', index:0, connected:true, axes:[0,0,0,0], buttons:[], mapping:'standard', timestamp:0, vibrationActuator: act };
  navigator.getGamepads = function(){ return [pad]; };
  return 'ok';
})()
"@ | Out-Null
    function Last { Js "JSON.stringify(window.__rumble.slice(-1)[0] || null)" }
    function Clear { Js "(function(){window.__rumble.length=0; return 1;})()" | Out-Null }
    $Au = "window.__Audio"
    Clear; Js "$Au.play('hurt', 1)" | Out-Null; Start-Sleep -Milliseconds 300
    "hurt: " + (Last)
    Start-Sleep -Milliseconds 400; Clear; Js "$Au.play('land', 0.5)" | Out-Null; Start-Sleep -Milliseconds 200
    "land 0.5: " + (Last)
    Clear; Js "$Au.play('select', 1)" | Out-Null; Start-Sleep -Milliseconds 200
    "select (no rumble): " + (Js "window.__rumble.length")
    # gyengébb nem vágja el az erősebbet
    Start-Sleep -Milliseconds 500; Clear; Js "(function(){ $Au.play('fall', 1); $Au.play('shoot', 1); return 1; })()" | Out-Null; Start-Sleep -Milliseconds 200
    "fall then shoot: " + (Js "JSON.stringify(window.__rumble)")
    # kikapcsolva
    Start-Sleep -Milliseconds 600; Clear; Js "(function(){ window.__Prefs.rumble=false; $Au.play('hurt', 1); window.__Prefs.rumble=true; return 1; })()" | Out-Null; Start-Sleep -Milliseconds 200
    "disabled: " + (Js "window.__rumble.length")
    # szünet: reset
    Clear; Js "(function(){ window.__ps.setPaused(true); return 1; })()" | Out-Null; Start-Sleep -Milliseconds 300
    "pause: " + (Js "JSON.stringify(window.__rumble)")
    Js "(function(){ window.__ps.setPaused(false); return 1; })()" | Out-Null
    "errors: " + ((Js "window.__errors") -join '; ')
} finally { Stop-Cdp }
