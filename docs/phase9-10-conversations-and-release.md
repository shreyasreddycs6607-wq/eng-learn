# Phase 9–10: Real-Life Practice and release checklist

## Conversation content (`assets/content/conversations.json`)

Fixed, pre-authored, offline. IDs `CONV001…`, turns ordered by explicit `order` (1..n, 4–8 turns).

```json
{ "id": "CONV003", "category": "shopping", "title": "Shopping",
  "kannadaTitle": "…", "kannadaSituation": "…", "situation": "…",
  "turns": [
    { "order": 1, "speaker": "shopkeeper", "kannadaText": "…", "englishText": "What do you want?",
      "audioPath": "audio/english/….wav", "responseExerciseIds": [] },
    { "order": 2, "speaker": "learner", "kannadaText": "…", "englishText": "I want milk.",
      "audioPath": "audio/english/….wav", "responseExerciseIds": ["ECV0302C", "ECV0302S"] } ] }
```

- Categories: `home family shopping phone travel doctor neighbour food`.
- Speakers: `learner family child shopkeeper friend conductor doctor neighbour waiter` (`speakerLabels` in `lib/models/conversation.dart`).
- A learner turn's two `responseExerciseIds` are ordinary entries in `exercises.json`: a `multipleChoice` (choose the reply) then a `speaking` (say it). They carry `"conversationId"` so a lesson's own practice list skips them; everything else (answer checking, `SpeakingEvaluator`, progress, mastery, revision) is the existing system.
- Validated by `ConversationValidator` (unique ids, 4–8 turns, contiguous order, known speakers, Kannada + English present, local `audio/` paths, exercises exist / right type / right `conversationId`). Never weaken it to make content pass.

## Retry contract (`ConversationController`)

Correct → advance. Incorrect #1 → correction + one retry. Incorrect #2 → answer revealed, continue (a wrong reply skips the speak step). Speaking: Good → advance; Almost / Try Again #1 → retry; #2 → target shown, continue. Listen Again records nothing and does not use an attempt; after 3 in a row the learner may continue. Every evaluated submission records exactly one attempt through `ExerciseProgressRepository`.

## Audio

All English audio in the app (229 clips, `assets/audio/english/*.wav`, ~10 MB) is **offline Windows SAPI placeholder speech** (Microsoft David) — robotic, but every English word, sentence, listening exercise and conversation line is playable offline. Replace with real recordings under the **same file names**; no code or JSON changes needed.

Before the production audit, 184 of the 230 audio paths in the curriculum pointed at `.mp3` files that did not exist (including 11 listening exercises, which were therefore unanswerable). `test/audio_assets_test.dart` now fails if any referenced clip is missing.

**Still missing:** all Kannada and Telugu audio. The one Telugu reference (`audio/telugu/water_telugu.mp3`) has no recording; the app hides audio buttons whose file is not bundled (`AudioService.hasAudio`), so nothing shows as broken. When a recording is added, remove it from `optionalMissing` in `test/audio_assets_test.dart`.

## Repetition and reminders

- **Spaced review (automatic, per exercise):** each correct answer pushes the exercise's next review further out — **1, 2, 4, 7 (weekly), 14, then 30 days (monthly)**, and it stays monthly after that. A wrong answer brings it back the next day. Today's Revision shows up to 8 due items. Defined in `RevisionScheduler.intervals`; mastery is unaffected (Comfortable starts after 3 correct reviews in a row).
- **Redo a finished lesson:** Progress screen -> tap a finished lesson (it shows a replay icon).
- **Daily reminder (opt-in):** Progress screen -> "Daily reminder" switch, default 6:00 PM, changeable. A local notification only (`flutter_local_notifications`); nothing is scheduled and no permission is requested until the switch is turned on. The choice is saved in the local database (schema v5) and re-applied at every app start. Adds the notification, vibrate and boot-completed permissions; still no internet permission.
- **Not verifiable without a phone:** that the notification actually appears. OPPO/realme (ColorOS) and some other phones stop background alarms unless the app is allowed to run in the background — if the reminder never shows, check Settings -> Battery -> App battery management (or "Auto-launch") for English Kaliyona.

## Kannada review needed

All Kannada in the conversations and reply exercises was written without a native reviewer. Have a fluent Kannada speaker read `conversations.json` before release, especially formality (`ನೀವು`) and the situation descriptions.

## On-device checklist (not verifiable from the development machine)

Install a release build (`flutter build apk --release`, needs Android SDK + JDK 17), then with Airplane Mode on:

- [ ] Clear app data → launch → Home → Continue opens the first lesson
- [ ] Kannada renders without clipping/overlap (short, long, mixed with English); text size readable
- [ ] English audio plays; Slow works; rapid taps never overlap; a missing clip does not crash
- [ ] Microphone: granted / denied / permanently denied / recognizer unavailable — app stays usable, "I repeated it" fallback works
- [ ] Speaking: exact phrase → Good; near miss → Almost/Try Again (never Good); silence → Listen Again
- [ ] Complete a lesson, 5+ exercises, 1 speaking exercise, 1 Today's Revision session, 1 conversation
- [ ] Force-close and reopen: attempts, mastery summary, due revision, streak all remain
- [ ] Each of the 8 conversations completes (4–8 turns, Kannada context, audio, choose, speak, feedback)
- [ ] Turn the daily reminder on for a time 2-3 minutes ahead: the permission prompt appears, and the notification arrives (also after a phone restart)
- [ ] Finish a lesson, then redo it from Progress
- [ ] Hand the phone to the learner without explanation; record hesitations; fix only what blocks her
