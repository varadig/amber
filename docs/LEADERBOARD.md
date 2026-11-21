# Globális ranglista (Supabase)

Ugyanaz a megoldás, mint a Moonshardban: a játék a futások eredményét egy Supabase táblába küldi (REST), és onnan olvassa a legjobb 10-et.
Beállítás: `assets/config/leaderboard.json` (url / key / table; beágyazva, módosítás után újra kell fordítani). Amíg az url vagy a kulcs üres,
a funkció nem látszik a játékban.

Jelenleg a Moonshard Supabase-projektjét használja, külön táblával: **`amber_scores`**. A táblát egyszer létre kell hozni (lásd lent);
amíg nincs meg, a lista "OFFLINE" üzenetet mutat, a beküldés pedig kihagyható (a játék működése nem függ tőle).

## A tábla létrehozása

Supabase → SQL Editor → futtasd:

```sql
create table public.amber_scores (
  id         bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  name       text not null check (name ~ '^[A-Z]{3}$'),
  score      int  not null check (score between 0 and 10000000),
  level      int  not null check (level between 1 and 99),
  atoms      int  not null default 0 check (atoms between 0 and 100000),
  completed  boolean not null default false,
  device     text check (device is null or length(device) <= 32)
);

create index amber_scores_score on public.amber_scores (score desc);

alter table public.amber_scores enable row level security;

-- Bárki olvashat és beküldhet, de módosítani / törölni nem lehet (nincs rá szabály).
create policy "read amber scores"   on public.amber_scores for select to anon using (true);
create policy "insert amber scores" on public.amber_scores for insert to anon with check (true);
```

A `check` megkötések a táblán érvényesülnek (3 nagybetű, ésszerű tartományok), így a hibás sorokat a szerver elutasítja.
Új projekthez: Project Settings → API: a **Project URL** és az **anon / publishable** kulcs kerül a `leaderboard.json`-be (a kulcs nyilvános,
a védelmet a Row Level Security adja).

## Működés

- **Játék vége** (az utolsó élet is elveszett, `PlayState`, GAME OVER): ha van pont, a `LeaderboardSubState` kéri a 3 betűs nevet
  (fel / le: betű, balra / jobbra: hely, betű be is gépelhető, Enter / A: küldés), beküldi (`Leaderboard.submit`: név, pont, elért pálya, atomok),
  majd mutatja a listát a friss sor kiemelésével. Bezárás után indul újra a játék.
- **Végigjátszás** (`EndState`): ugyanígy, `completed = true` (a listában KÉSZ / DONE).
- **Címképernyő**: L / négyzet (PS4) nyitja a listát (csak ha be van állítva).
- A név megjegyződik (FlxSave "amber-leaderboard"), eszközönként egy véletlen azonosító (`device`) is megy a későbbi szűréshez.
- Hálózati hiba: a lista "OFFLINE", a beküldés újrapróbálható (Enter) vagy kihagyható (ESC / B).
- Cheat-buildben (`-debug`, `-Dtest`, `-Dcheats`) nem lehet beküldeni, hogy a tesztelés ne szennyezze a listát (kivéve a teszt-paraméterrel, lent).

## Korlátok / csalás

A kulcs és a kliens kódja nyilvános, ezért egy elszánt játékos közvetlenül is beküldhet pontot (a megkötések csak az értelmetlen értékeket zárják ki).
Ha ez gondot okoz: Supabase Edge Function a beküldésre (pl. sebességkorlát eszközönként a `device` alapján), vagy utólagos szűrés SQL-ben.

## Tesztelés szerver nélkül

A `scripts/devserver.js` tartalmaz egy memóriában tárolt Supabase-mockot (`/rest/v1/<tábla>`). Cheat-buildben az URL-paraméterek felülírják a
beállítást és engedik a beküldést:

```
http://127.0.0.1:<port>/?lburl=http://127.0.0.1:<port>&lbkey=x
```

Automatikus teszt: `tests/leaderboard.ps1` (saját szervert indít a 3241-es porton).
