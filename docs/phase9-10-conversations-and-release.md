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

The 38 English conversation clips (`audio/english/conv_*.wav`) are **offline Windows SAPI placeholders** (Microsoft David), same as Phase 5. Replace with real recordings under the same file names. No Kannada/Telugu conversation audio exists yet.

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
- [ ] Hand the phone to the learner without explanation; record hesitations; fix only what blocks her
