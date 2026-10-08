# Nilu: current state of the app (code and repository inventory, 7 October 2026)

Method: I inspected the repository at `/Users/furkan/Desktop/RCApp` without changing it. HEAD is `5acc832` (3 Oct 2026). The repo has 208 commits from 17 Aug to 3 Oct 2026, 206 Dart files (~39,950 lines) in `lib/` and 175 test files. I did not run any build, test or formatter. Facts marked **from the development session** come from the coordinator's brief and cannot be checked in code. Sources are repository files given as `file://` links, with line numbers where useful. "en.json" means `lib/localization/en.json`, the English UI strings.

## 1. What user-facing features exist today?

### Takeaway
Nilu is an iOS-only Flutter app (iPhone and iPad) that works offline first. It has six main areas:
- **Cycle tracking:** a calendar, period start/end, predictions, a fertile window, a hormonal-contraception mode, and alerts for irregular cycles.
- **Daily logging:** flow or spotting, 8 symptoms, 7 moods, sexual activity, pain (level, location, context, and whether it stopped normal activities) and notes.
- **Insights:** a cycle-length trend, symptom frequency, symptom-by-phase analysis (Premium) and a rule-based "Ask your data" assistant.
- **Pregnancy mode:** the Turkish Ministry of Health antenatal schedule, appointments, warning-sign screens, blood-pressure and weight warnings, a pregnancy symptom list, a clinical summary, a month-by-month view, pregnancy in the calendar, and an end-of-pregnancy flow that covers every outcome.
- **Postpartum:** lochia tracking with a trend warning, and a manual return to cycle tracking.
- **Partner mode:** QR pairing that shares only an intimacy/closeness status.

Around these are reminders (including a discreet lock-screen mode), one Turkish-only home-screen widget, Apple Health period import, an app lock, a JSON backup, 5 library articles, and one recipe, one exercise and one yoga session.

### Cited Findings

#### Identity and platform
- The app shows on the device as "Nilu" (`CFBundleDisplayName` and `CFBundleName` = Nilu). Supported localizations: tr, en, de, es, fr, pt. iPhone runs portrait only; iPad supports all four orientations — [Info.plist](file:///Users/furkan/Desktop/RCApp/ios/Runner/Info.plist)
- Store names: "Nilu · Period Tracker" (EN) and "Nilu · Regl & Adet Takvimi" (TR). The EN subtitle is "Your cycle stays on your phone" — [STORE_LISTING.md](file:///Users/furkan/Desktop/RCApp/STORE_LISTING.md); commit "Türkçe adı 'Nilu · Regl & Adet Takvimi' yap" (27 Sep 2026)
- Version 1.0.0 build 1; bundle ID `com.furkan.rcperiodtracker`; minimum iOS 15.0 (widget extension: 17.0); iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`) — [STORE_CHECKLIST.md §1](file:///Users/furkan/Desktop/RCApp/STORE_CHECKLIST.md); [pubspec.yaml:19](file:///Users/furkan/Desktop/RCApp/pubspec.yaml)
- "The app is developed **only for iOS**. The Android, web and desktop platform folders were removed" — [README.md:13-15](file:///Users/furkan/Desktop/RCApp/README.md)

#### Onboarding
- The goal screen ("Which one describes you?") offers exactly two paths:
  - "I want to track my cycle" (periods, symptoms and predictions)
  - "I'm pregnant" (pregnancy weeks, check-ups and appointments)

  The copy says the choice can be changed later in Profile — en.json keys `onb_goal_*`, used in [onboarding_goal_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/onboarding_welcome/onboarding_goal_screen.dart)
- The cycle path asks for the last period start date ("If you are not sure, pick an approximate date"), the period length, and the cycle length. The cycle-length question has "I don't know" and "Skip" options — [onboarding_cycle_length_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/onboarding_welcome/onboarding_cycle_length_screen.dart), [onboarding_last_period_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/onboarding_welcome/onboarding_last_period_screen.dart)
- Routes exist for the welcome, goal, pregnancy, last-period, period-length, cycle-length and success steps — [route_names.dart](file:///Users/furkan/Desktop/RCApp/lib/core/navigation/route_names.dart)
- The "I'm pregnant" onboarding path landed on 2 Oct 2026 (commit 'Kurulumda "Hamileyim"') — `git log`; also **from the development session**

#### Cycle tracking and predictions
- **Period logging:**
  - Home has "My period started" and "My period ended" buttons with Undo. A period is saved open-ended, so the user does not tap "started" every day.
  - The calendar lets the user toggle a single day.
  - A period cannot start on a future date ("You cannot log a period on a future date").

  Sources: [period_service.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/period_service.dart); en.json `home_period_*` and `calendar_future_date_error`
- **Early start:** if the period starts before the predicted date, Home asks to confirm ("Did it start today? … the predictions will be recalculated") — en.json `home_period_early_*`, used in [period_toggle_button.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/home/widgets/period_toggle_button.dart)
- **How predictions are calculated:**
  - Average cycle length comes from "the last three **reasonable** cycles". Gaps that are too short or too long to be real cycles are ignored, and the user's own setting is the fallback.
  - Ovulation is placed a fixed luteal-phase length before the next predicted period.
  - Predictions reach past one year (the doc comment says thirteen cycles exceed a year).
  - Average period length uses only completed periods.

  Sources: [cycle_service.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/cycle_service.dart), [prediction_service.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/prediction_service.dart)
- **Fertility in the day sheet:** each day shows "Peak (ovulation day)", "High" or "Low", plus "Day {n} of your cycle" — en.json `day_detail_fertility_*`, used in [day_detail_bottom_sheet.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/calendar/widgets/day_detail_bottom_sheet.dart)
- **Hormonal contraception setting:** "I use hormonal contraception — Pill, hormonal IUD, implant or injection. When on, ovulation and fertility estimates are hidden." When on, ovulation and the fertile window are not calculated at all (phase `suppressed`) — en.json `cycle_settings_contraception*`; [prediction_service.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/prediction_service.dart); [cycle_info.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/models/cycle_info.dart)
- **Irregular cycles:** the Insights alert card flags four things ("not a diagnosis"):
  - cycles regularly shorter than 24 days or longer than 38 days (Office on Women's Health; PCOS is noted as a cause of long cycles)
  - noticeably varying cycle length (NHS)
  - repeated bleeding outside periods (NHS/ACOG)

  Sources: [cycle_alert.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/cycle_alert.dart); en.json `alert_*`
- **Variability message:** the trend card says "Your cycles vary noticeably" once the spread exceeds 8 days — en.json `insights_consult_*`
- **Lateness and unknown length:** the Home headline shows "{n} days late", "in {n} days" or "Cycle day {n}". Unknown length shows "Cycle length not known yet" — en.json `home_headline_*` and `home_ring_cycle_length_unknown`
- **Settings changes** apply "from today onward. Past cycle data is not affected." — en.json `cycle_settings_note`
- **Daylight-saving safety:** date math was made safe against time zones and daylight-saving changes. Before the fix, Berlin users saw due dates and cycle lengths shift by a day — [calendar_day.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/models/calendar_day.dart); commits "Döngü hesapları yaz saatinde kaymıyor" (3 Oct) and "Gebelik tarihleri yaz saatinde kaymıyor" (2 Oct); also **from the development session**
- **Heavy bleeding check:** Profile → "Is my bleeding heavy?" has 7 NHS signs to tick, gives "Worth seeing a clinician" if they fit, and prompts asking about iron when tiredness is ticked — [heavy_bleeding_check.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/heavy_bleeding_check.dart); en.json `bleeding_check_*`

#### Daily logging fields
All values are stored as language-independent codes — [log_vocabulary.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/models/log_vocabulary.dart)
- **Flow:** none, spotting, light, medium, heavy. Spotting does not start a period ("Light bleeding outside your period, too little to need a pad").
- **Symptoms (8):** cramp, headache, bloating, fatigue, tender (breasts), acne, appetite, backache.
- **Pregnancy symptoms (9, shown only in pregnancy):** nausea, vomiting, heartburn, swelling, itching, Braxton Hicks, constipation, frequent urination, leg cramps.
- **Moods (7):** happy, calm, sad, anxious, sensitive, irritable, tired.
- **Sexual activity:** none, protected, unprotected.
- **Pain:** level (mild, moderate, severe); "The pain stopped me doing normal activities today"; location (abdomen, lower back, pelvis, legs); context (intercourse, bowel, urination). The doc comments frame these as endometriosis signals (NICE/NHS) — [daily_log.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/models/daily_log.dart)
- **Notes:** free text — en.json `log_notes*`
- **Weight and blood pressure:** in pregnancy and postpartum only. "Outside pregnancy the thresholds are different (NICE NG136 home 135/85), so the measurement section exists only in pregnancy and postpartum" — [vitals.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/models/vitals.dart); [measurements_section.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/log_entry/widgets/measurements_section.dart)
- **Where logging happens:**
  - The "+" log screen (header "Today, {month} {day}") has flow, symptoms, mood, pain, measurements and notes.
  - The calendar day sheet for any past day has the period toggle, spotting, flow, symptoms, pain, mood, sexual activity and notes, but **no measurement fields**.

  Sources: en.json keys used by [log_entry_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/log_entry/log_entry_screen.dart) and [day_detail_bottom_sheet.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/calendar/widgets/day_detail_bottom_sheet.dart); also **from the development session** ("blood pressure/weight can only be entered for today")
- **Intimacy status** (Home, used for partner sharing): sexual desire at 4 levels ("Not interested right now" to "Feeling passionate") and 8 affection needs (hug, kiss, be near, hear voice, text, spend time, attention, alone time) — en.json `intimacy_*`; [intimacy_section.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/home/widgets/intimacy_section.dart)

#### Insights and assistant
- **Insights cards:**
  - Cycle Trend chart: average, "Last {count} cycles", steady/variable text
  - Symptom Analysis: most frequent symptoms as a percentage of logged days
  - Symptom-by-phase sentences, e.g. "{symptom} mostly occurs before your period" (Premium)
  - Cycle alerts

  Sources: [insights/widgets](file:///Users/furkan/Desktop/RCApp/lib/presentation/insights/widgets/); en.json `insights_*`
- **"Ask your data" assistant** (opened from the Insights app bar):
  - It has a closed set of 8 questions: next period, current phase, fertile window, cycle length, period length, regularity, symptom frequency, last symptom.
  - It is **not** connected to a language model: "regl verisi GDPR'da özel nitelikli veri" (period data is special-category data under GDPR).
  - The UI says "This is not a chatbot… Your questions never leave your device."

  Sources: [assistant_parser.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/assistant/assistant_parser.dart); [assistant_answer.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/assistant/assistant_answer.dart); en.json `assistant_*`

#### Clinical/doctor summary and export
- **Export My Data** (Profile → Privacy & Security):
  - Free users get the restorable **JSON backup** only.
  - Premium users get three files: JSON, a readable TXT **summary** and a **CSV** table.
  - Files go through the share sheet ("Then you choose where to save it"). They used to be copied to the clipboard, which was dropped as unsafe.

  Sources: en.json `privacy_export_desc*`; [data_export_service.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/data_export_service.dart); [privacy_security_screen.dart:497-555](file:///Users/furkan/Desktop/RCApp/lib/presentation/profile/privacy_security_screen.dart)
- **CSV columns:** date, is_period, flow, pain, pain_limited, pain_locations, pain_contexts, symptoms, moods, sexual_activity, weight_kg, systolic, diastolic, notes — [data_export_service.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/data_export_service.dart)
- **Cycle clinical summary (TXT):**
  - observed cycles; average, shortest and longest cycle, and the spread
  - threshold-based alerts
  - average and longest period
  - pain days, severe-pain days, days pain stopped normal activities
  - heavy-flow days; pain by location and context

  It is a pure calculation with no invented numbers — [clinical_summary.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/clinical_summary.dart)
- **Pregnancy and postpartum "Appointment summary":**
  - Contents: due date and how it was set, last period, how many readings were at or above 140/90, first/latest weight and the change, lochia, bleeding in pregnancy, symptoms of the last 14 days, check-ups done and coming up, and notes/questions.
  - Viewing it **on screen is free; sharing it as a file is Premium.**

  Sources: en.json `care_summary_*`; [care_summary_screen.dart:118](file:///Users/furkan/Desktop/RCApp/lib/presentation/pregnancy/care_summary_screen.dart); [PREGNANCY_MODE.md §0](file:///Users/furkan/Desktop/RCApp/PREGNANCY_MODE.md)
- **Restore from backup** (JSON): only missing days are added and nothing is deleted. The app reports "{n} records restored", and rejects unreadable, wrong-format or empty files — en.json `privacy_import_*`; [backup_import_service.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/backup_import_service.dart)

#### Reminders and notifications
- **Reminder types:** `periodApproaching`, `fertileWindow`, `dailyLog`, `care` — [reminder_planner.dart:10](file:///Users/furkan/Desktop/RCApp/lib/domain/services/reminder_planner.dart)
- **Timing rules:**
  - The period reminder fires 2 days before, at 09:00.
  - The fertile-window reminder fires at 09:00.
  - The daily-log reminder fires at 20:00.
  - At most 3 cycles are planned ahead, because iOS allows only 64 pending notifications.
  - The plan is rebuilt at launch and whenever predictions change.

  Sources: [reminder_planner.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/reminder_planner.dart) (constants `periodLeadDays = 2`, `morningHour = 9`, `dailyLogHour = 20`, `maxCycles = 3`); [reminder_sync.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/reminders/reminder_sync.dart)
- **Notification settings toggles:** Period Approaching, Fertile Window, Daily Log Reminder, Pregnancy and postnatal care, Discreet notifications — en.json `notif_*`; [notification_settings_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/profile/notification_settings_screen.dart)
- **Discreet mode:** the lock screen shows only "Reminder — You have a reminder for today". Titles of the user's own appointments are hidden too — [notification_settings.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/models/notification_settings.dart); [reminder_planner.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/reminder_planner.dart); en.json `notif_discreet_*`
- **Pregnancy and postnatal care reminders:** check-ups, screenings and supplements. The user's own appointments are reminded "the evening before". All pregnancy reminders stop as soon as a pregnancy is ended — en.json `care_empty` and `preg_end_what_happens`; [care_templates.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/care_templates.dart)
- **Permission rationale:** a "Reminders" explanation appears before the iOS prompt. "Not now" lasts only for the session: the code comment says it is asked again when the app is reopened. This is deliberate, because the reminder toggles still look on in settings — [reminder_sync.dart:53-61](file:///Users/furkan/Desktop/RCApp/lib/presentation/reminders/reminder_sync.dart); also **from the development session**
- **Remote push** (Firebase Cloud Messaging): a token is registered only if Firebase is configured and permission is already granted. No server sends pushes yet: `// TODO: Backend/Cloud Function tarafında push notification tetikleme` — [notification_service.dart](file:///Users/furkan/Desktop/RCApp/lib/data/datasources/remote/notification_service.dart); [intimacy_share_service.dart:24](file:///Users/furkan/Desktop/RCApp/lib/domain/services/intimacy_share_service.dart)

#### Home-screen widget
- **One iOS widget ("CycleWidget"),** small and medium sizes. It shows the cycle day, days until the next period and the phase name/color, or "Kayıt ekle" when there is no data — [CycleWidget.swift:199-217](file:///Users/furkan/Desktop/RCApp/ios/CycleWidget/CycleWidget.swift)
- **Data sharing:** the widget reads only derived numbers (cycle day, days to period, phase key) through the App Group. "Ham sağlık kaydı yazılmaz" (raw health records are not written) — [widget_snapshot.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/widget_snapshot.dart)
- **Turkish only:** all widget strings are hard-coded in Turkish ("DÖNGÜ GÜNÜ", "Regle {n} gün kaldı", "Kayıt ekle", display name "Döngü"). The extension has no localization folder — [CycleWidget.swift](file:///Users/furkan/Desktop/RCApp/ios/CycleWidget/CycleWidget.swift); `ls ios/CycleWidget` shows only the Swift file, Info.plist and entitlements
- **In-app preview does not match:** the Widgets preview screen shows a "Partner Widget" and a medium widget with a "DAILY TIP". The widget bundle contains only `CycleWidget()` — [widgets_preview_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/widgets_preview/widgets_preview_screen.dart); [CycleWidget.swift:214-217](file:///Users/furkan/Desktop/RCApp/ios/CycleWidget/CycleWidget.swift)
- **Needs a paid account:** the widget and HealthKit need the App Groups/HealthKit entitlements, which free Apple teams do not grant. They do not work in Debug builds — [README.md](file:///Users/furkan/Desktop/RCApp/README.md) "İmzalama ve yetkiler"

#### Apple Health
- **Permissions requested:** read menstruation flow, sleep and resting heart rate; write menstruation flow — [health_datasource.dart:35-44](file:///Users/furkan/Desktop/RCApp/lib/data/datasources/health_datasource.dart)
- **What is wired to the UI:** only **import of period records**. The Apple Health screen says "Days you marked yourself are kept; only missing periods are added" and "Data from Apple Watch and other apps arrives through Health." `averageSleepHours()` and `writePeriod()` exist but nothing calls them, and resting heart rate is never read — `grep` callers (0 outside the datasource); [health_sync_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/health_sync/health_sync_screen.dart)

#### Partner mode
- **Pairing:**
  - The QR holds a code that is separate from the user's ID and can be rotated (20 characters, ~100 bits, ambiguous characters left out).
  - Refreshing the code invalidates every QR shared earlier.
  - The scanner rejects the user's own code, existing partners, non-codes and unknown codes.
  - The scanning side sends a pairing request, which the owner must approve. The owner can revoke access.

  Sources: [pairing_token.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/pairing_token.dart); [partner_code.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/partner_code.dart); [firestore_datasource.dart:112-237](file:///Users/furkan/Desktop/RCApp/lib/data/datasources/remote/firestore_datasource.dart)
- **What is shared:** only the intimacy status — "Uygulamanın partnere gönderdiği tek veri bu" (this is the only data the app sends to the partner). It has one share toggle. Auto-share sends "10 seconds after a change", with "max 10" shares per day — [share_settings.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/models/share_settings.dart); [intimacy_share_service.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/intimacy_share_service.dart); en.json `intimacy_auto_share_desc` and `intimacy_rate_limit_msg`
- **What the partner sees:**
  - Partner tabs: Dashboard · Partner Guide · Profile.
  - The dashboard shows "How Are They Feeling?", "What Can You Do?" suggestions (rule engine), history, last-updated time with a warning after 24 h, mute notifications, and disconnect.
  - The **Partner Guide** is static text (a hard-coded "DAY 1", "Menstruation Phase", "Cycle: Day 1-5", "2.5 L" water) and has no data provider.

  Sources: [custom_bottom_nav.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/home/widgets/custom_bottom_nav.dart); [partner_dashboard_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/partner_match/partner_dashboard_screen.dart); [partner_support_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/partner_match/partner_support_screen.dart); en.json `partner_support_*` and `pv_*`
- **No pregnancy for partners:** in v1 the partner sees nothing about pregnancy — [PREGNANCY_MODE.md §0](file:///Users/furkan/Desktop/RCApp/PREGNANCY_MODE.md)
- **Firebase dependency:** partner sync needs Firebase. Without its configuration "the partner feature stays local" — [SETUP_KEYS.md §7](file:///Users/furkan/Desktop/RCApp/SETUP_KEYS.md)

#### App lock, backup, account
- **App lock:** uses the device's own authentication (Face ID/Touch ID, or the device passcode if no biometrics). It asks "on launch and when returning from the background". It is free and no app PIN is stored — [app_lock_service.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/app_lock_service.dart); en.json `lock_*`; [app_lock_gate.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/lock/app_lock_gate.dart)
- **Delete My Account:** wipes local data and the remote Firestore data, then returns to onboarding. **Log Out** ends the session and "Your saved health data stays on this device" — en.json `privacy_delete_*` and `logout_confirm_desc`

#### Content: health library, recipes, exercise, yoga
- **Health library:**
  - 5 articles: hormones through the cycle, nutrition and habits for PMS, talking to your partner, mood changes, iron deficiency.
  - 5 category tabs: popular, period, nutrition, psychology, exercise.
  - Sources cited: NHS and the Office on Women's Health.
  - It has search and a featured article.

  Sources: [article.dart:130-290](file:///Users/furkan/Desktop/RCApp/lib/domain/models/article.dart); en.json `library_article_*`
- **Recipes, exercise and yoga:**
  - **1 recipe** ("Salmon Quinoa Salad", opened from an article)
  - **1 exercise screen** ("Light Flow Yoga")
  - **1 guided yoga session** ("Gentle Flow Yoga", 6 timed poses)
  - The daily suggestion card sends strength/cardio to the exercise screen, and yin yoga, gentle movement and meditation to the yoga screen. Meditation goes to yoga because "elde ayrı bir meditasyon içeriği yok" (there is no separate meditation content).
  - There is no video. A dead play button was removed because "uygulamada video diye bir şey yok" (the app has no video).

  Sources: en.json `recipe_*` (25 keys), `exercise_*` (14) and `yoga_*` (26); [daily_suggestion_card.dart:214-226](file:///Users/furkan/Desktop/RCApp/lib/presentation/home/widgets/daily_suggestion_card.dart); [session_plan.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/session_plan.dart); [yoga_video_player.dart:48-51](file:///Users/furkan/Desktop/RCApp/lib/presentation/yoga/widgets/yoga_video_player.dart)
- **Phase guide:** text for each phase (menstrual, follicular, ovulation, luteal), plus "suppressed" (contraception) and "unknown" — [phase_guide.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/phase_guide.dart); en.json `phase_*`

#### Appearance
- **Theme colors:** 4 colors: Plum (free), Ocean, Forest, Graphite (Premium). Only the brand color changes; period and ovulation colors stay the same in every theme — [app_flavor.dart](file:///Users/furkan/Desktop/RCApp/lib/design_system/app_flavor.dart); en.json `appearance_desc`
- **Dark mode:** follows the system (`themeMode: ThemeMode.system`); there is no in-app light/dark switch — [main.dart:179](file:///Users/furkan/Desktop/RCApp/lib/main.dart); [appearance_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/appearance/appearance_screen.dart)

#### Pregnancy mode
Status: phases 0–2 are in code; phase 3 (weekly content, partner view) is "left to the first update" — [PREGNANCY_MODE.md §0](file:///Users/furkan/Desktop/RCApp/PREGNANCY_MODE.md)
- **Setup:**
  - The due date comes either from the last period, corrected for cycle length (EDD ≈ LMP + 280 + (cycle length − 28)), or from a date the doctor gave. The due date can always be edited.
  - The setup screen explains what changes: period and fertility predictions pause, bleeding is not recorded as a period, and reminders follow check-ups.
  - Schedule choice: "Turkish Ministry of Health schedule" or "My own appointments".

  Sources: [pregnancy_setup_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/pregnancy/pregnancy_setup_screen.dart); en.json `preg_setup_*`; [PREGNANCY_MODE.md §2.1](file:///Users/furkan/Desktop/RCApp/PREGNANCY_MODE.md)
- **Template by language:** the Turkish template is the default only in Turkish. Other languages start with an empty list and "add your own appointment" — [care_templates.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/care_templates.dart); [PREGNANCY_MODE.md §0](file:///Users/furkan/Desktop/RCApp/PREGNANCY_MODE.md)
- **Turkish antenatal template** (Ministry of Health guideline, 2018; codes `tr_visit_1..4`, `tr_screen_*`, `tr_supp_*`, `tr_vacc_tetanus`):
  - **Visits:** weeks 0–13, 18–24, 24–28, 36–38. A pregnancy marked after week 14 still gets visit 1 (the guideline's "first visit" rule).
  - **Screenings:** nuchal translucency + combined test (weeks 11–14), AFP (16–20), triple/quad test (16–20), anomaly scan (18–22), 75 g oral glucose tolerance test (24–28), indirect Coombs/anti-D (28).
  - **Supplements:** vitamin D and tetanus vaccine from week 12, iron from week 16.

  Source: [care_templates.dart:60-160](file:///Users/furkan/Desktop/RCApp/lib/domain/services/care_templates.dart)
- **Appointments** (Care tab): add your own, set date and time, "Remind me", notes ("Questions for your doctor, results…"), mark done, delete. The template's source is shown — en.json `care_*`; [care_list_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/pregnancy/care_list_screen.dart)
- **Tabs:** in pregnancy and postpartum the third tab becomes "Care" (appointments) in place of Insights — [custom_bottom_nav.dart:40-58](file:///Users/furkan/Desktop/RCApp/lib/presentation/home/widgets/custom_bottom_nav.dart)
- **Pregnancy home:**
  - A week + day ring ("You are {w} weeks and {d} days pregnant"), trimester (ACOG boundaries), due date.
  - Next check-up.
  - "Something not right?", which opens warning signs in one tap.
  - "Month by month".

  Sources: [pregnancy_home_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/pregnancy/pregnancy_home_screen.dart); [pregnancy_ring.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/pregnancy/pregnancy_ring.dart); [pregnancy.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/models/pregnancy.dart); en.json `preg_week_day_sentence` and `preg_trimester_label`
- **Warning signs:**
  - 13 pregnancy signs, following the Ministry's list.
  - 8 postpartum signs plus a mental-health emergency note.
  - A note on baby movements: "There's no need to count movements… if movements slow down or change, get checked the same day."
  - An emergency number by device region (e.g. 112 in the EU, 999 in the UK); otherwise "call your local emergency number".

  Sources: en.json `danger_*`; [danger_signs_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/pregnancy/danger_signs_screen.dart); [emergency_number.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/emergency_number.dart)
- **Blood-pressure warnings** (free):
  - At or above 140/90: rest, measure again, and contact the doctor the same day if still high.
  - At or above 160/110: get care now.
  - High blood pressure together with headache, swelling or vomiting: pre-eclampsia warning.
  - Thresholds follow NICE NG133 and ACOG PB 222.

  Sources: [vitals.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/models/vitals.dart); en.json `bp_*`
- **Symptom warnings:** picking a pregnancy symptom that is on the warning list (severe headache, sudden swelling, persistent vomiting, unexplained itching) adds a note — [log_vocabulary.dart:67-83](file:///Users/furkan/Desktop/RCApp/lib/domain/models/log_vocabulary.dart); en.json `log_preg_symptom_note`
- **Bleeding in pregnancy** is never recorded as a period. A dialog tells the user to contact their doctor — [life_stage.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/models/life_stage.dart); en.json `preg_bleeding_dialog_*`; test `pregnancy_blocks_period_logging_test.dart`
- **End pregnancy:**
  - Outcomes: birth, miscarriage, termination, ectopic, stillbirth, or "undisclosed". A reason is never required.
  - Records are kept and reminders stop immediately.

  Sources: [pregnancy.dart:9-17](file:///Users/furkan/Desktop/RCApp/lib/domain/models/pregnancy.dart); en.json `preg_end_*`
- **Month by month:** 9 months mapped onto trimesters, with the check-ups in each month — [pregnancy_month.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/models/pregnancy_month.dart); [pregnancy_months_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/pregnancy/pregnancy_months_screen.dart)
- **Pregnancy in the calendar:** each day shows its pregnancy week, the due date and appointments. Only ongoing pregnancies and pregnancies that ended in birth appear; losses do not show while browsing the calendar — [pregnancy_calendar.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/pregnancy_calendar.dart)
- **No kick counter, by design:** RCOG Green-top 57 does not recommend formal movement counting, and the Ministry list says "report decreased movements" — [PREGNANCY_MODE.md §2.4](file:///Users/furkan/Desktop/RCApp/PREGNANCY_MODE.md)

#### Postpartum, past pregnancies, trying to conceive
- **Postpartum home:**
  - Day counter ("Day of birth" or "Day {n}").
  - "Today's bleeding" (lochia) logging. A trend warning fires when "bleeding has increased again after easing" or "is getting heavier", based on the Ministry's postnatal guideline.
  - Information: you can get pregnant before your first period; supplements continue.
  - "Return to period tracking" ("nothing is deleted").

  Sources: [postpartum_home_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/pregnancy/postpartum_home_screen.dart); [lochia_trend.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/lochia_trend.dart); en.json `pp_*`
- **Postnatal template:** visits on days 2–5, 13–17 and 30–42, plus supplements (not reminded by default). The design doc says the postnatal stage closes after day 42 — [care_templates.dart:160-195](file:///Users/furkan/Desktop/RCApp/lib/domain/services/care_templates.dart); [LIFE_STAGES.md §2](file:///Users/furkan/Desktop/RCApp/LIFE_STAGES.md)
- **After returning to cycle tracking,** Home shows "Waiting for your first period" — en.json `home_headline_after_pregnancy`
- **Past pregnancies:** a list plus a record for each ("Weeks at the end", outcome and date, symptoms over the whole pregnancy, daily notes). Ended pregnancies "aren't deleted; they stay here" — [past_pregnancies_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/pregnancy/past_pregnancies_screen.dart); en.json `past_preg_*`; commit "Geçmiş gebelikler" (2 Oct)
- **Trying to conceive** (Profile only): reminds about folic acid and when to see a doctor. The doctor timing follows ASRM: after 12 months under 35, after 6 months at 35 or over, straight away at 40 or over; the age comes from the profile birth date — [conception_intent.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/models/conception_intent.dart); en.json `profile_preg_ttc*`

### Inferences
- Nilu's main differentiators against Flo and Clue are in **pregnancy safety and clinical accuracy**: the Turkish Ministry schedule, the warning-sign screens, blood-pressure thresholds, lochia trend detection, no kick counter, and a calm end flow that covers every outcome. Its cycle-tracking and content breadth is basic: 5 articles, 1 recipe, 1 exercise screen, 1 yoga session, and no video or meditation audio.
- Several features are thinner than they look: the widget is Turkish-only; Health integration is import-only; partner sync needs Firebase, which is not configured, and has no push; the Partner Guide is static. A feature-by-feature comparison should count these as "partial".

### Gaps
- I could not check runtime behavior such as rendering, animations or real notification delivery. Only static code and tests were read.
- I did not confirm whether the home-screen widget suppresses its period countdown during pregnancy. `WidgetSnapshot.from(CycleInfo)` has no life-stage branch ([calendar_view_model.dart:420-427](file:///Users/furkan/Desktop/RCApp/lib/presentation/calendar/view_models/calendar_view_model.dart)), but whether `CycleInfo` is empty during a pregnancy break was not traced.

## 2. Which features are Premium, what are the ad placements and policy, and what pricing is defined?

### Takeaway
Premium (RevenueCat entitlement `premium`) unlocks five things:
- full cycle history in the trend chart (12 cycles instead of 3)
- symptom-by-phase analysis
- the readable TXT summary and CSV export (and sharing the pregnancy summary as a file)
- 3 extra theme colors
- no ads

Everything to do with safety, privacy and data rights is free: the app lock, JSON backup and restore, pregnancy warning signs, appointments, blood-pressure warnings and the on-screen summary. Ads are one non-personalized AdMob banner, only in the health library and article screens. There are no prices in code. The docs set Turkish prices at 99.99 TL/month and 599.99 TL/year; European prices are a proposal only.

### Cited Findings
- **PremiumGate rules:**
  - `freeCycleHistory = 3`; `cycleHistoryLimit = isPremium ? 12 : 3`
  - `canSeePhaseBreakdown = isPremium`
  - `showsAds = !isPremium`
  - `canExportBackup() => true` ("a right under KVKK and GDPR; it cannot be tied to payment")
  - `canExportReports = isPremium` (TXT + CSV)

  Source: [premium_gate.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/premium_gate.dart)
- **Where the gate is applied:** cycle trend card, symptom analysis card, care-summary sharing, privacy export, and the ad banner — `grep PremiumGate.` across `lib/`: [cycle_trend_card.dart:38](file:///Users/furkan/Desktop/RCApp/lib/presentation/insights/widgets/cycle_trend_card.dart), [symptom_analysis_card.dart:36](file:///Users/furkan/Desktop/RCApp/lib/presentation/insights/widgets/symptom_analysis_card.dart), [care_summary_screen.dart:118](file:///Users/furkan/Desktop/RCApp/lib/presentation/pregnancy/care_summary_screen.dart), [privacy_security_screen.dart:497](file:///Users/furkan/Desktop/RCApp/lib/presentation/profile/privacy_security_screen.dart), [ad_banner.dart:56](file:///Users/furkan/Desktop/RCApp/lib/presentation/widgets/ad_banner.dart)
- **Themes:** non-default theme colors require Premium (`requiresPremium => this != free`; free = Plum) — [app_flavor.dart:51-55](file:///Users/furkan/Desktop/RCApp/lib/design_system/app_flavor.dart)
- **Paywall benefit list (5):**
  - "Your full cycle history — The free version shows your last {free} cycles; Premium shows all of it."
  - "Symptom–phase analysis"
  - "Data export — A readable summary and a table you can take to a clinician. The restorable backup is free for everyone."
  - "Custom themes"
  - "No ads"

  The class comment says the list was trimmed to reality: it "used to promise five things, one was already free (app lock) and three did not exist" — [premium_screen.dart:14-27, 489-520](file:///Users/furkan/Desktop/RCApp/lib/presentation/premium/premium_screen.dart); en.json `premium_feature_*`
- **Paywall details:**
  - Prices come live from RevenueCat offerings (`offerings.current`); no price is hard-coded.
  - Supported plan lengths: weekly, monthly, 2, 3 and 6 months, annual.
  - The saving percentage is computed from real prices and hidden below 5%. "Best value" is the plan with the lowest monthly equivalent. Introductory offers are shown.
  - Restore Purchases, "Manage subscription" (a Settings deep-link hint), the auto-renew disclaimer, and Privacy/Terms links are present.

  Sources: [subscription_pricing.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/subscription_pricing.dart); [premium_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/premium/premium_screen.dart); [SETUP_KEYS.md §4-5](file:///Users/furkan/Desktop/RCApp/SETUP_KEYS.md)
- **Decided Turkish pricing:** monthly **99.99 TL**, yearly **599.99 TL** (50.00 TL/month, "50% cheaper" badge). The suggested product IDs are `rc_premium_monthly` and `rc_premium_annual` — [SETUP_KEYS.md:188-196, 240](file:///Users/furkan/Desktop/RCApp/SETUP_KEYS.md)
- **European pricing (proposal, not decided):** 3.99 €/month and 23.99 €/year, or 4.99 €/29.99 €. The doc recommends applying to the App Store Small Business Program (15% commission instead of 30%) — [SETUP_KEYS.md:211-236](file:///Users/furkan/Desktop/RCApp/SETUP_KEYS.md)
- **RevenueCat key is a placeholder:** `_appleApiKey = 'appl_api_key_placeholder'; // TODO`. Without a real key the paywall cannot sell (all six entry points are guarded). The SDK is configured only on iOS ("Android için eklenebilir" — can be added for Android) — [subscription_service.dart:8-9, 42-47](file:///Users/furkan/Desktop/RCApp/lib/domain/services/subscription_service.dart); [STORE_CHECKLIST.md §6](file:///Users/furkan/Desktop/RCApp/STORE_CHECKLIST.md)
- **Ad placement:** `AdBanner` appears in exactly two places, the health library list and the article screen — [health_library_screen.dart:91](file:///Users/furkan/Desktop/RCApp/lib/presentation/health_library/health_library_screen.dart); [article_screen.dart:197](file:///Users/furkan/Desktop/RCApp/lib/presentation/health_library/article_screen.dart)
- **Ad format:** an inline adaptive banner, full width, at most 90 pt tall, inside scrolling content (not a fixed bar) — [ads_datasource.dart:70-97](file:///Users/furkan/Desktop/RCApp/lib/data/datasources/ads_datasource.dart)
- **Ad policy:**
  - `AdRequest(nonPersonalizedAds: true)`; ad content rating capped at G.
  - No advertising identifier (IDFA) and no App Tracking Transparency prompt; `NSPrivacyTracking` is false.
  - 50 SKAdNetwork IDs.
  - The Google consent form (UMP) is shown on the first screen with an ad, not at launch. If consent fails, no ad is requested. "Change ad preferences" appears in Privacy & Security only when Google requires it.

  Sources: [ads_datasource.dart](file:///Users/furkan/Desktop/RCApp/lib/data/datasources/ads_datasource.dart); [ad_consent.dart](file:///Users/furkan/Desktop/RCApp/lib/data/datasources/ad_consent.dart); [STORE_CHECKLIST.md "Reklam"](file:///Users/furkan/Desktop/RCApp/STORE_CHECKLIST.md); [PrivacyInfo.xcprivacy](file:///Users/furkan/Desktop/RCApp/ios/Runner/PrivacyInfo.xcprivacy)
- **Ads still use Google test IDs:** app ID `ca-app-pub-3940256099942544~1458002511` and banner `ca-app-pub-3940256099942544/2934735716`. Test ads carry a "Test mode" badge, which App Review can read as an unfinished app — [Info.plist](file:///Users/furkan/Desktop/RCApp/ios/Runner/Info.plist); [ads_datasource.dart:23](file:///Users/furkan/Desktop/RCApp/lib/data/datasources/ads_datasource.dart); [SUBMIT.md §0](file:///Users/furkan/Desktop/RCApp/SUBMIT.md)
- **Pregnancy free/Premium rule:** "nothing safety-related can be behind the paywall". Marking a pregnancy, weeks, appointments and reminders, warning signs and the end flow are free. Weekly content, the clinical summary as a file, the partner view, and weight/blood-pressure charts were listed as "may be Premium" — [PREGNANCY_MODE.md §3](file:///Users/furkan/Desktop/RCApp/PREGNANCY_MODE.md)

### Inferences
- The Premium offer is narrow compared with Flo Premium or Clue Plus: there are no extra content libraries, coaching or health reports beyond the TXT/CSV export. The ad load is light (two library screens only), so "no ads" is a weak upgrade reason.
- **Copy mismatch:** the paywall and store listing promise Premium "shows all of it" / "full cycle history", but the code caps the trend chart at 12 cycles (`isPremium ? 12 : 3`).

### Gaps
- No free trial or introductory offer is configured in code. Trials would be set in App Store Connect, and that state is not visible in the repo.
- Final European and other regional prices are not decided ("henüz karara bağlanmadı", not yet decided).

## 3. Which languages are supported and how complete is localization?

### Takeaway
There are six languages: Turkish (reference), English (fallback), German, Spanish, French and Portuguese. All six have exactly 1054 keys, none missing or empty. The weak spots are:
- the Portuguese register mixes European and Brazilian forms
- the home-screen widget is Turkish-only
- the pregnancy check-up template exists only for Turkish users
- all six legal texts still contain the e-mail placeholder

### Cited Findings
- **Key counts** (Python check of `lib/localization/*.json`):
  - tr = en = de = es = fr = pt = **1054 keys**, 0 missing against tr, 0 extra, 0 empty values.
  - Only 2–3 values per language (longer than 12 characters) are identical to English.

  Sources: [lib/localization/](file:///Users/furkan/Desktop/RCApp/lib/localization/); parity is also enforced in CI by [tool/check_localization.dart](file:///Users/furkan/Desktop/RCApp/tool/check_localization.dart) and [.github/workflows/ci.yml](file:///Users/furkan/Desktop/RCApp/.github/workflows/ci.yml)
- **Locale order:** `appSupportedLocales = [en, tr, de, fr, es, pt]`. English is first, so a phone in any unsupported language falls back to English rather than Turkish — [supported_locales.dart](file:///Users/furkan/Desktop/RCApp/lib/localization/supported_locales.dart)
- **No in-app language picker:** "the app has no language setting of its own; it follows the system" — [STORE_CHECKLIST.md:118-119](file:///Users/furkan/Desktop/RCApp/STORE_CHECKLIST.md)
- **iOS permission texts:** `CFBundleLocalizations` lists the same six languages. Each `*.lproj/InfoPlist.strings` localizes the camera, Face ID, Health-read and Health-write descriptions in all six — [Info.plist](file:///Users/furkan/Desktop/RCApp/ios/Runner/Info.plist); [ios/Runner/*.lproj](file:///Users/furkan/Desktop/RCApp/ios/Runner/)
- **Store listing:** written in all six languages and checked for character limits by a script — [STORE_LISTING.md](file:///Users/furkan/Desktop/RCApp/STORE_LISTING.md); [tool/check_store_listing.py](file:///Users/furkan/Desktop/RCApp/tool/check_store_listing.py)
- **Portuguese register is mixed** (substring counts across pt.json values): "registo" 31 vs "registro" 20; "aplicação" 15 vs "aplicativo" 6; "partilhar" 13 vs "compartilhar" 7; "ecrã" 1 vs "tela" 8; "você" 40 alongside "teu/teus" 93. The first form in each pair is European, the second Brazilian — my count over [pt.json](file:///Users/furkan/Desktop/RCApp/lib/localization/pt.json). Choosing between BR and PT Portuguese is an open launch decision **from the development session**.
- **Legal-text placeholder in all 6 languages:** `[E-POSTA ADRESİ]` / `[EMAIL ADDRESS]` / `[E-MAIL-ADRESSE]` / `[DIRECCIÓN DE CORREO]` / `[ADRESSE E-MAIL]` / `[ENDEREÇO DE E-MAIL]`, in `privacy_policy_section9_content` and `terms_section12_content` — my scan of the 6 JSON files
- **Turkish-only parts:**
  - the antenatal/postnatal template ("Yalnızca Türkçe'de varsayılan", default only in Turkish) — [PREGNANCY_MODE.md §0](file:///Users/furkan/Desktop/RCApp/PREGNANCY_MODE.md); [care_templates.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/care_templates.dart)
  - the home-screen widget's strings — [CycleWidget.swift](file:///Users/furkan/Desktop/RCApp/ios/CycleWidget/CycleWidget.swift)
- **Outdated doc:** TESTING.md still says "Turkish and English are fully translated. German/Spanish/French/Portuguese **fall back to English**". This is contradicted by the key parity above and by commit "Altı dili tamamla" (complete six languages) — [TESTING.md:124-125](file:///Users/furkan/Desktop/RCApp/TESTING.md)

### Inferences
- For comparison purposes, Nilu supports 6 languages at full key parity. Flo and Clue cover around 20+ languages (to be checked by other researchers). Nilu's localization depth (legal texts, permission strings, store listing) is good for an app before launch.
- Native-quality review of de/es/fr/pt (beyond key presence) has not been documented, and whether the health content suits each market (NHS/OWH sources, Turkey-only schedule) is a market-fit question.

### Gaps
- Key parity does not prove translation quality. I found no record of a native-speaker review for de/es/fr/pt.

## 4. Data and privacy model

### Takeaway
No account or login is needed. Health data stays on the device in the iOS Keychain through `flutter_secure_storage`. When Firebase is configured, it receives only:
- an anonymous user ID and a profile document (createdAt, isPartner/hasPartner, partner list, push-notification tokens)
- the intimacy status, if the user shares it with a partner
- pairing codes

Cycle logs are never uploaded: the upload method exists but nothing calls it. RevenueCat sees purchase status, and AdMob sees device and connection data for non-personalized ads. Firebase is not configured in the repo today, so the app currently runs fully on-device. Export (JSON free, TXT/CSV Premium) and full account deletion exist.

### Cited Findings
- **Encrypted store:** `SecureStore` writes to the iOS Keychain (`KeychainAccessibility.first_unlock`; the doc comment notes these items travel with encrypted device backups). Sensitive keys:
  - period_logs, daily_logs, cycle and period length, settings_updated_at
  - intimacy_*
  - profile_name, profile_email, profile_birth_date
  - pregnancies, care_events, conception_intent

  Non-sensitive preferences (onboarding flag, notification toggles) stay in plain `SharedPreferences` — [secure_store.dart](file:///Users/furkan/Desktop/RCApp/lib/data/local/secure_store.dart); [README.md "Depolama"](file:///Users/furkan/Desktop/RCApp/README.md)
- **Identity:** `ensureMyId()` uses Firebase anonymous sign-in if Firebase is reachable, otherwise a local UUID. `completeOnboarding()` creates `users/{uid}` with `{createdAt, isPartner, hasPartner}` and registers the push token, all of which does nothing when Firebase is absent. Onboarding always completes even if the remote side fails — [user_view_model.dart:113-162](file:///Users/furkan/Desktop/RCApp/lib/domain/view_models/user_view_model.dart)
- **Firebase not configured yet:** the app "works without Firebase configuration (local-only mode): all data stays on the device". `ios/Runner` contains no `GoogleService-Info.plist` and `lib/` has no `firebase_options.dart` — [README.md:23-33](file:///Users/furkan/Desktop/RCApp/README.md); directory listings
- **Remote data, collection by collection** (when Firebase is on):
  - `users/{uid}`: partners, hasPartner, fcmTokens
  - `intimacy/{uid}`: sexualDesire, affectionNeeds, timestamp, isShared
  - `pairingTokens/{token}`: ownerUid, plus a `requests` subcollection
  - `users/{uid}/logs` exists, but `saveDailyLog` has **no callers** ("defined but not called from anywhere")

  Sources: [firestore_datasource.dart](file:///Users/furkan/Desktop/RCApp/lib/data/datasources/remote/firestore_datasource.dart); [intimacy_share_service.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/intimacy_share_service.dart); [notification_service.dart](file:///Users/furkan/Desktop/RCApp/lib/data/datasources/remote/notification_service.dart); [STORE_CHECKLIST.md:336-337](file:///Users/furkan/Desktop/RCApp/STORE_CHECKLIST.md)
- **Firestore rules:** owners only. A partner can read `intimacy/{uid}` only when approved. Pairing tokens can be fetched individually but not listed. Everything else is denied (`match /{document=**} … if false`) — [firestore.rules](file:///Users/furkan/Desktop/RCApp/firestore.rules)
- **Sign in with Apple is never called.** `signInWithApple()` exists in the auth datasource and the entitlement `com.apple.developer.applesignin` is present, but no code calls it (grep: 0 callers). Even so, the privacy policy §5 says "Sign in with Apple for authentication", and SUBMIT.md tells App Review that Apple sign-in is "only for partner pairing and optional" — [firebase_auth_datasource.dart:33](file:///Users/furkan/Desktop/RCApp/lib/data/datasources/remote/firebase_auth_datasource.dart); [Runner.entitlements](file:///Users/furkan/Desktop/RCApp/ios/Runner/Runner.entitlements); en.json `privacy_policy_section5_content`; [SUBMIT.md:209-210](file:///Users/furkan/Desktop/RCApp/SUBMIT.md)
- **Privacy policy §5:** "Your cycle records, symptoms, pain records and notes are not sent to any of them… Your pregnancy and postnatal records and your blood pressure and weight readings are not sent to these services either." **§6:** ads are not personalized; the ad network receives technical device and connection information such as the IP address. Last updated 2 Oct 2026 — en.json `privacy_policy_section5_content`, `privacy_policy_section6_content`, `privacy_policy_last_updated`
- **Privacy manifest:** declares Health, User ID, Device ID (app functionality and third-party advertising) and Purchase History, all linked and none for tracking. `NSPrivacyTracking` is false. The only reason-required API is UserDefaults (CA92.1) — [PrivacyInfo.xcprivacy](file:///Users/furkan/Desktop/RCApp/ios/Runner/PrivacyInfo.xcprivacy)
- **RevenueCat** receives purchase and subscription status. `SubscriptionService.login(uid)` has no callers, so purchases stay under RevenueCat's anonymous app user — [subscription_service.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/subscription_service.dart); grep (only `logout` is called, at [user_view_model.dart:92, 246](file:///Users/furkan/Desktop/RCApp/lib/domain/view_models/user_view_model.dart))
- **Apple Health** data is processed on the device ("The data never leaves your device") — en.json `health_sync_point_local`
- **Deletion:** "Delete My Account" removes local data and, when Firebase is used, also:
  - revokes partner access and cancels the pairing code
  - deletes `users/{uid}`, its logs and `intimacy/{uid}`
  - deletes the Firebase identity (re-sign-in may be needed: "Your data was deleted. To remove your account completely, sign in again and retry")

  Sources: [firestore_datasource.dart:239-280](file:///Users/furkan/Desktop/RCApp/lib/data/datasources/remote/firestore_datasource.dart); [firebase_auth_datasource.dart:56-80](file:///Users/furkan/Desktop/RCApp/lib/data/datasources/remote/firebase_auth_datasource.dart); en.json `privacy_delete_*`; [STORE_CHECKLIST.md §4 "Hesap silme"](file:///Users/furkan/Desktop/RCApp/STORE_CHECKLIST.md)
- **Store-listing privacy pitch:** "Your data is written to your device, not a server — no account, no tracking"; "PRIVACY ISN'T A FEATURE HERE, IT'S THE ARCHITECTURE" — [STORE_LISTING.md (English)](file:///Users/furkan/Desktop/RCApp/STORE_LISTING.md)
- **Encryption declaration:** `ITSAppUsesNonExemptEncryption` is false — [Info.plist](file:///Users/furkan/Desktop/RCApp/ios/Runner/Info.plist)

### Inferences
- The privacy model is the strongest point against Flo (cloud account by default) and is close to Apple Cycle Tracking and Stardust's privacy positioning. The cost is no multi-device sync and no cloud restore beyond the manual JSON file. Keychain items may also ride along in encrypted iPhone backups.
- The Sign in with Apple mismatch (claimed in the policy, the entitlement and the App Review notes, but never used) should be fixed one way or the other before review. It is a privacy-label consistency risk.
- Requesting HealthKit sleep, resting heart rate and write access that the app never uses is out of line with the usage string ("used to improve cycle predictions"). It is likely an App Review risk under data minimization.

### Gaps
- The App Store Connect "App Privacy" answers are not in the repo; only a recommended mapping is ([STORE_CHECKLIST.md §4](file:///Users/furkan/Desktop/RCApp/STORE_CHECKLIST.md)).
- I could not verify whether the Keychain data is really included in iCloud or Finder device backups in practice.

## 5. Accessibility, device sizes, dark mode and iPad support

### Takeaway
iPad and foldable widths are designed for: a responsive layout with a side navigation rail at 900 pt or wider, and two columns in the library and Insights. Tests check 11 device sizes, every screen (empty and with data), and WCAG contrast in light and dark across all 4 themes. Dark mode follows the system. Accessibility work beyond contrast is thin: only 5 explicit Semantics/label usages, no explicit Dynamic Type handling found, and no VoiceOver tests.

### Cited Findings
- **Layout by width:**
  - Under 600 pt: one column with a bottom bar.
  - 600–899 pt: a centered 600 pt column.
  - 900 pt or wider: a centered column plus a side navigation rail.
  - The library and Insights go to two columns from 700 pt, up to 1000 pt.
  - Decisions use the current width, not the device type (iPadOS window resizing, foldables).

  Sources: [README.md "Ekran uyumu"](file:///Users/furkan/Desktop/RCApp/README.md); [app_layout.dart](file:///Users/furkan/Desktop/RCApp/lib/design_system/app_layout.dart); [side_nav_rail.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/home/widgets/side_nav_rail.dart)
- **Device-size test:** checks for no layout overflow on iPhone 16e, iPhone 17, iPhone 17 Pro Max, "iPhone Duo" (closed and open), iPad mini, iPad (A16), iPad Pro 11", iPad Pro 13" portrait and landscape — [device_sizes_test.dart](file:///Users/furkan/Desktop/RCApp/test/presentation/device_sizes_test.dart)
- **Every-screen tests:** every screen draws without layout errors (`every_screen_test`), including with edge-case data (`every_screen_with_data_test`: irregular cycles, longest period, an unfinished period) — [every_screen_test.dart](file:///Users/furkan/Desktop/RCApp/test/presentation/every_screen_test.dart); [every_screen_with_data_test.dart](file:///Users/furkan/Desktop/RCApp/test/presentation/every_screen_with_data_test.dart)
- **Contrast:** WCAG contrast is measured on the real `ThemeData`, light and dark × four themes. Brand colors are chosen for at least 4.5:1 — [theme_contrast_test.dart](file:///Users/furkan/Desktop/RCApp/test/design_system/theme_contrast_test.dart); [TESTING.md §5](file:///Users/furkan/Desktop/RCApp/TESTING.md); [app_flavor.dart](file:///Users/furkan/Desktop/RCApp/lib/design_system/app_flavor.dart)
- **Dark mode:** `themeMode: ThemeMode.system`. The launch screen has light and dark variants so dark mode no longer flashes white — [main.dart:179](file:///Users/furkan/Desktop/RCApp/lib/main.dart); [STORE_CHECKLIST.md §3](file:///Users/furkan/Desktop/RCApp/STORE_CHECKLIST.md)
- **iPad:** supported, with all four orientations allowed. Store screenshots exist for iPhone 6.9" (5 per language) and iPad 13" (3 per language): 48 images — [Info.plist](file:///Users/furkan/Desktop/RCApp/ios/Runner/Info.plist); [STORE_CHECKLIST.md §3](file:///Users/furkan/Desktop/RCApp/STORE_CHECKLIST.md)
- **Fonts:** Inter and Fraunces are bundled in the app rather than downloaded at runtime — [README.md "Yazı tipleri"](file:///Users/furkan/Desktop/RCApp/README.md)
- **Accessibility code:** only 5 occurrences of `Semantics(`, `semanticsLabel`, `semanticLabel`, `excludeSemantics` or `MergeSemantics` in `lib/` (e.g. `insights_symptoms_semantics`). No `textScaler` or `TextScaler` handling was found — grep over `lib/`

### Inferences
- Because Flutter's Material widgets provide default semantics, basic VoiceOver probably works. But charts, the calendar grid and the cycle ring may lack spoken descriptions, and large Dynamic Type sizes are untested. This is a likely gap against Apple Cycle Tracking, which is native and accessible by default.

### Gaps
- No VoiceOver or Dynamic Type audit or tests were found, so I cannot judge real screen-reader quality.

## 6. Known gaps, rough edges and launch blockers

### Takeaway
The code is close to ready (1878 passing tests **from the development session**; CI checks format, analysis, tests and localization). Launch is blocked by owner-side business, legal and account work:
- legal review of the privacy policy and terms
- the support e-mail placeholder
- a public privacy-policy URL
- the Apple Developer Program, plus the Paid Apps agreement and bank/tax setup
- production RevenueCat, AdMob and Firebase keys
- the BR vs PT Portuguese decision

There are also a number of product gaps and claim mismatches that should be fixed or reworded before submission.

### Cited Findings
**Launch blockers**
- **Owner-side blockers (from the development session):**
  - legal review of the privacy policy and terms
  - the Portuguese BR vs PT register decision
  - the support e-mail placeholder `[E-POSTA ADRESİ]`
  - a public privacy-policy URL
  - the Apple Paid Apps agreement and bank/tax setup
  - production RevenueCat, AdMob and Firebase keys
- **Repo checklist:** Apple Developer Program membership "⬜ engelleyici" (blocking); privacy-policy URL; real AdMob IDs; RevenueCat key + `premium` entitlement; `GoogleService-Info.plist` — [SUBMIT.md §0](file:///Users/furkan/Desktop/RCApp/SUBMIT.md)
- **Selling needs Business setup:** the Paid Applications Agreement, a bank account and W-8BEN must be completed; without them products stay "Waiting for Agreement" — [SETUP_KEYS.md §1](file:///Users/furkan/Desktop/RCApp/SETUP_KEYS.md)
- **Other pre-launch tasks:**
  - App Store subscription products (with review screenshot and localizations) must be added to the version, or they sit in "Missing Metadata".
  - The AdMob GDPR message, `app-ads.txt` and a marketing URL.
  - Deploy the Firestore rules and upload the APNs key.

  Sources: [SETUP_KEYS.md §4, §6, §7](file:///Users/furkan/Desktop/RCApp/SETUP_KEYS.md); [SUBMIT.md §7](file:///Users/furkan/Desktop/RCApp/SUBMIT.md)
- **Placeholders in code:** RevenueCat key `appl_api_key_placeholder` and Google test ad IDs — [subscription_service.dart:8-9](file:///Users/furkan/Desktop/RCApp/lib/domain/services/subscription_service.dart); [ads_datasource.dart:23](file:///Users/furkan/Desktop/RCApp/lib/data/datasources/ads_datasource.dart)
- **Legal text status:**
  - Governing law (Türkiye, Istanbul courts) and the data controller ("Hürkan Çelebi, Bağcılar/İstanbul, Türkiye") **are now filled in**.
  - Only the e-mail placeholder remains, in 6 languages.
  - STORE_CHECKLIST still lists `[UYGULANACAK HUKUK]` (governing law) and the controller as blockers, so the doc is out of date.

  Sources: en.json `terms_section12_content` and `privacy_policy_section9_content`; commits "Şartlardaki hukuk seçimini doldur" and "Veri sorumlusunu doldur" (26 Sep); [STORE_CHECKLIST.md:216-237](file:///Users/furkan/Desktop/RCApp/STORE_CHECKLIST.md)
- **Health content review:** an expert review of the health content is pending ("⬜") — [STORE_CHECKLIST.md §5](file:///Users/furkan/Desktop/RCApp/STORE_CHECKLIST.md)
- **Name availability:** whether "Nilu" is free in App Store Connect is still to be checked — [STORE_CHECKLIST.md:261-264](file:///Users/furkan/Desktop/RCApp/STORE_CHECKLIST.md)

**Product gaps from the development session (simulator testing, early Oct 2026), with code corroboration**
- **The notification rationale returns on every cold launch after "Not now".** This is deliberate. Corroborated: "Oturumla sınırlı: uygulamayı yeniden açtığında tekrar sorulur" (session-scoped: asked again when the app is reopened) — [reminder_sync.dart:53-61](file:///Users/furkan/Desktop/RCApp/lib/presentation/reminders/reminder_sync.dart)
- **Blood pressure and weight can only be entered for today.** Corroborated: measurements live only on the "Today" log screen; the day sheet has no measurement fields — [measurements_section.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/log_entry/widgets/measurements_section.dart); [day_detail_bottom_sheet.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/calendar/widgets/day_detail_bottom_sheet.dart)
- **A pregnancy marked by mistake cannot be deleted, only ended,** and then stays in past pregnancies. Corroborated: no pregnancy delete in the view model, repository or past-pregnancies screen (only `removeEvent` for care items); "Your pregnancy record and appointments aren't deleted" — [pregnancy_view_model.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/view_models/pregnancy_view_model.dart); en.json `preg_end_what_happens`
- **"Trying to conceive" is offered only in Profile.** There is no "I recently gave birth" onboarding path. Corroborated: the onboarding goal has only "track my cycle" and "I'm pregnant" — [onboarding_goal_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/onboarding_welcome/onboarding_goal_screen.dart)
- **The app is iOS only** — [README.md:13](file:///Users/furkan/Desktop/RCApp/README.md)

**Rough edges found in code**
- **Store listing (EN) claims that do not match the code:**
  - "Daily log — flow, pain, mood, **sleep**, notes": there is no sleep log field, and the Health sleep reader has no callers.
  - "Apple Health — import your period records, **write the days you mark back**": `writePeriod()` has no callers.
  - "Movement — yoga flows, stretches and **breathing exercises** matched to your phase": there is one yoga session and one exercise screen, and meditation routes to yoga.
  - The listing has **0 mentions of pregnancy**, so the main new feature is missing from the store text.

  Sources: [STORE_LISTING.md](file:///Users/furkan/Desktop/RCApp/STORE_LISTING.md); [health_datasource.dart](file:///Users/furkan/Desktop/RCApp/lib/data/datasources/health_datasource.dart); [daily_suggestion_card.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/home/widgets/daily_suggestion_card.dart)
- **Unused HealthKit permissions:** sleep, resting heart rate and write access are requested, but only period import is used — [health_datasource.dart:35-44](file:///Users/furkan/Desktop/RCApp/lib/data/datasources/health_datasource.dart); [health_sync_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/health_sync/health_sync_screen.dart)
- **Sign in with Apple:** implemented and declared in the entitlement, the policy and the review notes, but never called (see §4).
- **Partner side:**
  - The Partner Guide is static demo content ("DAY 1", "Menstruation Phase") whatever the user's real phase.
  - Partner push notifications are not implemented (Cloud Function TODO), yet the partner dashboard has "Mute Notifications".

  Sources: [partner_support_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/partner_match/partner_support_screen.dart); [intimacy_share_service.dart:24](file:///Users/furkan/Desktop/RCApp/lib/domain/services/intimacy_share_service.dart); en.json `pv_mute`
- **Widget:** Turkish-only strings. The in-app widget preview advertises a "Partner Widget" and a "Daily tip" widget that do not exist — [CycleWidget.swift](file:///Users/furkan/Desktop/RCApp/ios/CycleWidget/CycleWidget.swift); [widgets_preview_screen.dart](file:///Users/furkan/Desktop/RCApp/lib/presentation/widgets_preview/widgets_preview_screen.dart)
- **Premium copy:** "Premium shows all of it" vs a 12-cycle cap in code — [premium_gate.dart:21-22](file:///Users/furkan/Desktop/RCApp/lib/domain/services/premium_gate.dart); en.json `premium_feature_history_desc`
- **Content is thin:** 5 articles, 1 recipe, 1 exercise screen, 1 yoga session (see §1)
- **Accountless Log Out:** Profile shows "Log Out" even though there is no account; it returns to the welcome screen while data stays — en.json `logout_confirm_desc`
- **Minor:**
  - RevenueCat log level is `LogLevel.debug` in all builds — [subscription_service.dart:39](file:///Users/furkan/Desktop/RCApp/lib/domain/services/subscription_service.dart)
  - the pubspec description is still "A new Flutter project." — [pubspec.yaml](file:///Users/furkan/Desktop/RCApp/pubspec.yaml)
- **Outdated docs:**
  - TESTING.md says "561 tests in 46 files" and that only TR/EN are complete.
  - SUBMIT.md and STORE_CHECKLIST.md say "1049 tests".
  - The current figure is **1878 passing tests (from the development session)**. My static count is 1275 `test(`/`testWidgets(` call sites across 175 files; loops expand this into more cases.

  Sources: [TESTING.md:164](file:///Users/furkan/Desktop/RCApp/TESTING.md); [SUBMIT.md:46](file:///Users/furkan/Desktop/RCApp/SUBMIT.md); [STORE_CHECKLIST.md:305](file:///Users/furkan/Desktop/RCApp/STORE_CHECKLIST.md)

**Roadmap items not yet built**
- **v1.1:** EPDS postnatal-depression screening (needs legal review) and a pelvic-floor program.
- **v1.2:** menopause transition and postmenopause; packaging the pain diary; a birth-control pill reminder.
- **Later:** weekly pregnancy content and a partner pregnancy view.

Source: [LIFE_STAGES.md §6](file:///Users/furkan/Desktop/RCApp/LIFE_STAGES.md); [PREGNANCY_MODE.md §0, §8](file:///Users/furkan/Desktop/RCApp/PREGNANCY_MODE.md)

**Completed in early October 2026 (from the development session, corroborated by git log)**
- 1 Oct: pregnancy mode phase 0; bleeding in pregnancy blocked from period logging.
- 2 Oct: the life-stage architecture, the Turkish care schedule and reminders, discreet notifications, warning-sign screens, lochia trend, blood pressure and weight, the appointment summary, "Ay ay gebelik" (month by month), "Takvimde gebelik" (pregnancy in calendar), 'Kurulumda "Hamileyim"' (I'm pregnant in onboarding), "Geçmiş gebelikler" (past pregnancies), and "Lohusalıktan regl takibine dönülebilsin" (return from postpartum to cycle tracking).
- 2–3 Oct: date math made safe against daylight-saving changes.

Source: `git log --since=2026-09-25`

### Inferences
- The fastest path to submission is: fill the e-mail; publish the policy URL; get the legal review; buy the membership and complete the agreements; enter the keys. Then fix the claim mismatches, either by removing the "sleep", "write back" and "breathing" claims from the listing or by building them, and either remove or wire up Sign in with Apple and the unused HealthKit types. Mismatches between the listing, the privacy labels and actual behavior are common App Review rejection reasons (guidelines 2.1, 2.3 and 5.1.1).

### Gaps
- I did not review legal texts for legal adequacy (out of scope and needs a lawyer).
- I did not verify the App Store Connect, RevenueCat, AdMob or Firebase console states; they are not in the repo.

## 7. What Nilu does NOT have that period or pregnancy apps commonly have (absence confirmed in code)

### Takeaway
None of the following exist in the code:
- an Android app or Apple Watch app
- cloud sync
- a community or forum
- pill or medication reminders
- basal body temperature, LH/ovulation-test or pregnancy-test logging
- PCOS or perimenopause/menopause modes
- a kick counter (deliberately excluded) or contraction timer
- weekly baby-development content
- baby tracking after birth
- religious-practice features
- a discreet app icon
- multiple profiles

Several of these are explicitly on the roadmap or excluded by design.

### Cited Findings
- **Android:** none. There is no `android/` folder (`ls` fails), and the README says "only iOS". `SubscriptionService.init` returns early on non-iOS ("Android için eklenebilir"). The Flutter code base could produce Android later (`flutter create --platforms=android .`) — [README.md:13-15](file:///Users/furkan/Desktop/RCApp/README.md); [subscription_service.dart:42-47](file:///Users/furkan/Desktop/RCApp/lib/domain/services/subscription_service.dart)
- **Apple Watch app:** none. No watchOS target or WatchKit references in `ios/` or `lib/`. Watch data reaches Nilu only indirectly, through HealthKit period import ("Apple Watch ve diğer uygulamaların verisi HealthKit üzerinden geliyor", Apple Watch and other apps' data arrives through HealthKit) — grep; [Runner.entitlements](file:///Users/furkan/Desktop/RCApp/ios/Runner/Runner.entitlements); [health_import.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/health_import.dart)
- **Cloud sync across devices:** none. No iCloud/CloudKit code. Firestore is used only for identity, partner and intimacy data, and the daily-log upload is never called. The only cross-device path is a manual JSON backup and restore. The architecture doc says any future cloud sync "will be designed end-to-end encrypted" — grep; [firestore_datasource.dart](file:///Users/furkan/Desktop/RCApp/lib/data/datasources/remote/firestore_datasource.dart); [architecture.md](file:///Users/furkan/Desktop/RCApp/architecture.md)
- **Community/forum:** none — grep `forum|community` gives 0 hits in Dart, en.json and iOS
- **Pill reminder:** none. `ReminderType` has only `periodApproaching, fertileWindow, dailyLog, care`. "Pill" appears only in the hormonal-contraception description. A pill reminder is planned for v1.2 — [reminder_planner.dart:10](file:///Users/furkan/Desktop/RCApp/lib/domain/services/reminder_planner.dart); [LIFE_STAGES.md §5-6](file:///Users/furkan/Desktop/RCApp/LIFE_STAGES.md)
- **Medication reminders:** none in general. The only supplement or vaccine items are the pregnancy/postnatal care items (vitamin D, iron, tetanus) and the folic-acid reminder for trying to conceive — [care_templates.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/care_templates.dart); [conception_intent.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/models/conception_intent.dart)
- **Basal body temperature:** none. No temperature field in `DailyLog` or `LogVocabulary`. The only "temperature" in en.json is yoga copy, and "fever above 38 °C" appears only as warning-sign text — [log_vocabulary.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/models/log_vocabulary.dart); grep
- **Ovulation/LH test and pregnancy test logging:** none. 0 hits for `ovulation_test|lh_test|opk|pregnancy_test`. A pregnancy is marked manually. "Positive test → pregnancy mode" appears only as an idea in the roadmap — grep; [LIFE_STAGES.md §3](file:///Users/furkan/Desktop/RCApp/LIFE_STAGES.md)
- **PCOS mode:** none. "PCOS" appears only in code comments explaining the alert for long cycles (> 38 days); there is no PCOS mode or copy (0 hits in en.json) — [cycle_alert.dart:24](file:///Users/furkan/Desktop/RCApp/lib/domain/services/cycle_alert.dart)
- **Perimenopause/menopause mode:** none. `LifeStage` = `cycle, pregnancy, postpartum` only; 0 hits for "menopause". The roadmap proposes STRAW+10-based detection for v1.2 — [life_stage.dart:28-31](file:///Users/furkan/Desktop/RCApp/lib/domain/models/life_stage.dart); [LIFE_STAGES.md §4](file:///Users/furkan/Desktop/RCApp/LIFE_STAGES.md)
- **Kick counter:** none, **by deliberate clinical decision**: "Sayaç yok" (no counter), based on RCOG GTG 57 and the Ministry list. The app explains instead that there is no need to count movements — [PREGNANCY_MODE.md §2.4](file:///Users/furkan/Desktop/RCApp/PREGNANCY_MODE.md); en.json `danger_movements_note_body`
- **Contraction timer:** none — grep `contraction`: 0 hits
- **Weekly baby-development content:** none. Phase 3, "left to the first update". Fruit-size comparisons "cannot be the main content". The only "fruit" hit in en.json is the iron article — [PREGNANCY_MODE.md §0, §3, §8](file:///Users/furkan/Desktop/RCApp/PREGNANCY_MODE.md); [LIFE_STAGES.md §6](file:///Users/furkan/Desktop/RCApp/LIFE_STAGES.md)
- **Baby tracking after birth** (feeding, diapers, growth, vaccines): none. Breastfeeding tracking and baby growth/vaccine tracking are listed as **out of scope** — grep 0 hits; [PREGNANCY_MODE.md §3 "Kapsam dışı"](file:///Users/furkan/Desktop/RCApp/PREGNANCY_MODE.md)
- **Religious-practice features** (e.g. prayer or fasting exemptions during a period): none. The only grep hits for "namaz" are fragments of Turkish verb forms in comments (e.g. "alınamaz", "bulunamaz"), and there is nothing in the l10n files — grep
- **Discreet app icon:** none. No `CFBundleAlternateIcons` or `setAlternateIconName`. Only *discreet notifications* exist — [Info.plist](file:///Users/furkan/Desktop/RCApp/ios/Runner/Info.plist); [notification_settings.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/models/notification_settings.dart)
- **Multiple profiles:** none. One user per device. Partner is a separate *role* on another phone ("Partner modu… bir kullanıcı rolü", partner mode is a user role) — [life_stage.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/models/life_stage.dart); grep
- **Also absent:** an in-app language picker ([STORE_CHECKLIST.md:118](file:///Users/furkan/Desktop/RCApp/STORE_CHECKLIST.md)); an in-app light/dark toggle ([main.dart:179](file:///Users/furkan/Desktop/RCApp/lib/main.dart)); videos and meditation audio ([yoga_video_player.dart:48-51](file:///Users/furkan/Desktop/RCApp/lib/presentation/yoga/widgets/yoga_video_player.dart)); an EPDS depression screen ([LIFE_STAGES.md §2](file:///Users/furkan/Desktop/RCApp/LIFE_STAGES.md)); an LLM chat assistant, deliberately ([assistant_parser.dart](file:///Users/furkan/Desktop/RCApp/lib/domain/services/assistant/assistant_parser.dart)); a web or desktop version ([README.md](file:///Users/furkan/Desktop/RCApp/README.md))

### Inferences
- Against Flo and Clue, the biggest functional gaps are Android, sync and backup to the cloud, BBT and LH logging (core for trying to conceive), a pill reminder, and weekly pregnancy content.
- Against Apple Cycle Tracking, the gap is Apple Watch integration (wrist temperature, retrospective ovulation estimates), since Nilu only imports period days from Health.
- Against pregnancy apps, the gaps are weekly baby content, the kick counter (deliberately absent), a contraction timer and baby tracking.
- Religious-practice features, a discreet icon and a perimenopause mode could be differentiators in Nilu's Turkish and European markets. These are inferences for the comparison writer, not claims about competitors.

### Gaps
- Absence was confirmed by keyword grep over `lib/`, `lib/localization/en.json` and `ios/Runner` + `ios/CycleWidget`. A feature built under an unexpected name could be missed, but none of the screens, routes or models listed in [route_names.dart](file:///Users/furkan/Desktop/RCApp/lib/core/navigation/route_names.dart) suggest any of the absent features.
