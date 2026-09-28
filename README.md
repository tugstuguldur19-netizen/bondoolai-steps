# Бондоолой

Алхам тоолдог тоглоом. Та алхах тусам таны дүр — Бондоолой — туранхай, гоё болно.
A step-counter game: your chubby, cute character slims down into a handsome
young man or a pretty young woman as you walk.

## Features

- **Choose a character** on first launch: **Хүү** (boy) or **Охин** (girl).
  Changeable any time in Settings.
- **Background step counter**: a native foreground service
  (`StepCounterService.kt`) listens to the phone's step sensor all day, starts
  on boot and after app updates, and shows a quiet notification with today's
  steps. Counting never waits for the app to be opened; the app reads the
  service's per-day totals (`StepStore.kt`).
- **Samsung Health (via Health Connect)**: Settings → "Samsung Health холбох".
  Samsung Health counts steps in the background all day; the app reads its
  daily totals through Android Health Connect (refreshed on open and every 2
  minutes while open) and, per day, shows whichever of phone sensor / Health
  Connect saw more steps. Requires Android 8.0+.
- **6 body levels** (1 = fit … 6 = obese) per gender, from the reference art
  (`assets/characters/{boy,girl}_level{1..6}.png`). The day starts at level 6
  when the goal is 10,000+ steps, or level 5 for smaller goals, and steps down
  evenly to level 1 as today's steps reach the goal.
- **Items fitted to every level**: hats, tops, shoes and the belt are
  pre-fitted onto each of the 12 bodies (`assets/layers/`, offsets in
  `layers.json`) with soft contact shadows; the belt wraps around the belly
  behind the arms, and when shoes are worn the figure's own sneakers are cut
  away (`*_erase_shoes` masks). Deels are complete outfits (with their own hat and boots),
  widened at runtime to each level's body width.
- **Daily goal** (default 10,000), editable in Settings.
- **Market (Зах)**: 4 deels (Казах, Буриад, Халх, Торгон), 4 hats, a
  cashmere sweater and two Соёмбо hoodies, running and winged shoes, and a
  champion belt with a gold Соёмбо. Earn coins by watching rewarded ads.
- **History (Түүх)**: last-30-days chart with goal line, best day, average,
  total, goal streak, and a day-by-day record list.
- **Friends (Найзууд)**: pick a display name, share an invite with your
  6-character friend code, add friends by code, and see who leads
  **today / last 7 days / last 30 days**.
- Entire UI in Mongolian.

## Getting the APK

Every push to `main` builds the app on GitHub Actions and publishes it as a
GitHub Release. On your phone, open:

**https://github.com/tugstuguldur19-netizen/bondoolai-steps/releases/latest**

and download `bondoolai.apk`, then open it to install (allow "install from
unknown sources" when asked). New builds install over the old one and keep
your data, because every build is signed with the same test key
(`android/app/debug.keystore`).

> Before publishing to the Play Store, replace that checked-in test key with a
> private upload key that is **not** stored in git.

## Setting up Friends & Leaderboard (one time, free)

Friends' step counts are exchanged through a free [Supabase](https://supabase.com)
project. Until it's configured the Friends tab shows "not activated" and
everything else works normally.

1. Create a free account at supabase.com → **New project** (any name, e.g.
   `bondoolai`; pick the region closest to Mongolia, e.g. Singapore/Tokyo).
2. **SQL Editor** → **New query** → paste the entire contents of
   [`supabase/schema.sql`](supabase/schema.sql) → **Run**.
3. **Authentication → Sign In / Providers** → turn on
   **Allow anonymous sign-ins** → Save.
4. **Project Settings → API**: copy the **Project URL** and the
   **anon public** key and put them in `lib/config.dart` (`supabaseUrl`,
   `supabaseAnonKey` default values). The anon key is designed to be public;
   the row-level-security rules in the schema protect the data.

Users get an anonymous account automatically — no email or password. Each
person only ever sees their own profile and the totals of people they are
friends with.

## Ads

The app uses **Google's public test ad unit IDs**, which show placeholder test
ads and earn nothing. Before publishing, create an AdMob app and replace the
App ID in `android/app/src/main/AndroidManifest.xml` and `rewardedAdUnitId`
in `lib/state/ad_service.dart`.

## Building locally

```bash
flutter pub get
flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk
```

The project is pinned to Flutter 3.27.1 (see the workflow).

## Code map

| Path | What |
|---|---|
| `lib/widgets/character.dart` | Draws the body for the level + item layers, or a widened deel |
| `lib/models/items.dart` | Market catalog (slots, names, prices, asset paths) |
| `lib/state/app_state.dart` | Steps, history, goal, coins, wardrobe, gender |
| `lib/state/social_state.dart` | Supabase REST client: anonymous auth, profile, friends, leaderboard |
| `lib/screens/` | Home, Friends, History, Shop, Settings, character picker |
| `supabase/schema.sql` | Database tables, security rules, `add_friend` / `leaderboard` functions |
