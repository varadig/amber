# Kiadás itch.io-ra

1. `itch.config.json`: `user` (itch.io felhasználónév) és `game` (a projekt URL-neve: `https://<user>.itch.io/<game>`).
2. Először a `scripts/release.ps1 -SkipPublish`-sel készíts zip-et, és ellenőrizd (`dist/amberascent-html5.zip`).
3. Feltöltés: `scripts/release.ps1` (vagy csak `scripts/publish-itch.ps1`). A butler első használatkor böngészős bejelentkezést kér (vagy `BUTLER_API_KEY` környezeti változó).
4. Az első feltöltés után az itch.io projekt-oldalán: Kind of project = HTML, a fájlnál "This file will be played in the browser", Viewport 960 x 540, Fullscreen button be.
5. A játék belső felbontása 480x270, a vászon kitölti az ablakot; a billentyűzet-vezérlés miatt asztali böngészőre való (telefonos érintés még nincs).
