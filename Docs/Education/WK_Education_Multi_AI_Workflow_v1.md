# WebKurier Education - Multi-AI Lesson Workflow v1

Status: APPROVED pilot standard
Date: 2026-09-21

## Purpose
Create one canonical lesson package for both iOS and Android. Platform code may differ, but educational content, evidence rules, TTS script and lesson metadata stay aligned.

## Core principles
- VERIFIED = independently confirmed fact/result.
- INFERRED = reasoned hypothesis that still requires verification.
- UNKNOWN = insufficient evidence.
- AI output is not VERIFIED by default.
- Engineering cycle: Inspect -> Understand -> Plan -> Implement -> Test -> Review.
- First lessons target roughly 9-11 minutes of finished audio, not a 45-minute monologue.
- English technical terms are paired with Russian equivalents.

## Multi-AI production pipeline
1. GPT / ChatGPT - Course Architect and canonical author.
2. Claude - Education Review: pedagogy, structure, beginner progression.
3. Qwen - Beginner Clarity Review when the lesson is concept-dense.
4. Grok - Creative and TTS polish: natural speech, rhythm, transitions, light humor.
5. Gemini - Compression Review when a lesson is too long or repetitive.
6. DeepSeek - Technical second opinion for engineering terminology and disputed details.
7. Perplexity - External fact verification for history, standards, current versions and claims that need sources.
8. GPT / ChatGPT - Final approval and release of one canonical version.

Not every lesson must use every model. During the pilot, Claude and Grok are routine reviewers; Qwen, Gemini, DeepSeek and Perplexity are triggered by need.

## Quality gate before release
- Required lesson topics are present.
- No model invented missing evidence.
- No fabricated real student/teacher stories.
- Historical and current factual claims are verified when needed.
- TTS text has no garbage tokens, broken words, citation markers or service chatter.
- Technical absolutes are avoided unless justified.
- AI claims are classified only after verification.
- Runtime metadata and TTS script agree on lesson ID, language and duration.
- One canonical content package is shared across iOS and Android.

## Canonical lesson package
Required runtime files:
- lesson.json
- lesson01_ru_tts.txt
- visuals.json

Shared schema:
- WK_Lesson_Package_Schema_v1.json

## Platform placement
iOS documentation: Docs/Education/
iOS runtime: Resources/Education/Lessons/week01/lesson01/

Android documentation: docs/education/
Android runtime: app/src/main/assets/education/lessons/week01/lesson01/

Important: content placement is separate from app integration. Loading/parsing code, Xcode resource inclusion, UI wiring and audio playback are separate implementation tasks and require their own tests.

## Safety / governance
- One task -> one branch -> one PR.
- No automatic merge or deployment.
- Keep existing Copilot MVP branches and PRs isolated.
- Do not modify unrelated architecture files in this content-only task.
