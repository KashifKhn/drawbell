---
title: "DrawBell Difficulty Guide: Easy, Medium, and Hard Mode Explained"
description: "A complete guide to DrawBell's three difficulty modes — how confidence thresholds work, what the mercy rule does, and which mode is right for you."
publishedDate: 2025-03-15
author: "Kashif Khan"
tags: ["guide", "difficulty", "tips", "alarm"]
---

DrawBell has three difficulty levels. Choosing the wrong one means either waking up successfully every morning, or being able to dismiss the alarm half-asleep. Here's exactly how each mode works and how to pick the right one.

## How Difficulty Works

DrawBell's AI model outputs a **confidence score** between 0–100% for each of the 345 possible categories. Higher confidence means the drawing more clearly resembles the prompt.

Difficulty controls two things:
1. **Confidence threshold**: How confident the AI must be before it accepts your drawing
2. **Match rule**: Whether only the top-1 prediction counts, or top-3

---

## Easy Mode

| Setting | Value |
|---------|-------|
| Confidence threshold | 40% |
| Match rule | Top-3 prediction |
| Mercy rule | After 5 failed attempts, threshold drops 10% |

On Easy mode, the alarm dismisses if *any* of the AI's top-3 predictions matches your prompt with at least 40% confidence.

This means: if you draw something that looks a bit like a cat (even if it also looks like a lion or a bear), the alarm will dismiss. You need a recognizable drawing, but it doesn't have to be precise.

**Who should use Easy mode**: People who are light sleepers and just need a gentle nudge to engage their brain. New users who want to build familiarity with the drawing mechanics. Anyone whose artistic skills are genuinely limited.

After 5 failed attempts in Easy mode, the mercy rule kicks in and the threshold drops to 30%. This ensures you won't be stuck indefinitely on a difficult category.

---

## Medium Mode

| Setting | Value |
|---------|-------|
| Confidence threshold | 60% |
| Match rule | Top-1 prediction only |
| Mercy rule | After 10 failed attempts, threshold drops 10% |

Medium mode is the recommended setting for most people.

Only the model's *top-1 prediction* counts — if it thinks your drawing looks more like a lion than a cat, even at 55% confidence, the cat alarm won't dismiss. You need the drawing to be clearly recognizable as the right thing.

At 60% confidence, you need to draw the defining features of the object. A cat needs ears, eyes, maybe whiskers. A bicycle needs two wheels and a frame. A house needs walls and a roof. Sketchy is fine; unrecognizable is not.

**Who should use Medium mode**: Most users — especially people who have found Easy mode too permissive and Hard mode too brutal. This is the sweet spot where you must genuinely engage your brain but don't need to be an artist.

The mercy rule activates after 10 failed attempts, which covers truly difficult categories like "The Mona Lisa" or "saxophone."

---

## Hard Mode

| Setting | Value |
|---------|-------|
| Confidence threshold | 75% |
| Match rule | Top-1 prediction only |
| Mercy rule | None |

Hard mode has no mercy. The top-1 prediction must match at 75%+ confidence, and there are no bailouts regardless of how many attempts you make.

At 75% confidence, your drawing must be clearly, unambiguously recognizable. The model was trained on 50 million+ drawings; at 75% it expects something that genuinely resembles the canonical Quick Draw style of the category.

This mode is genuinely difficult for some categories. If you get "saxophone" on Hard mode, you need to draw a recognizable saxophone — not just a vague curved shape.

**Who should use Hard mode**: Heavy sleepers who are motivated to improve their waking habits. People who want a real challenge. Anyone who finds they can dismiss Medium mode without fully engaging their brain.

A practical note: on Hard mode, there is no internet connection needed and no timeout. The alarm will continue ringing until you draw correctly. Plan accordingly.

---

## Tips for All Modes

**Draw the defining features first.** The AI processes your entire drawing after each stroke, but it's looking for shape signatures. Get the core shape down early — the head circle for a cat, the wheel circles for a bicycle — before adding details.

**Big and clear beats small and detailed.** The input to the model is 28 × 28 pixels. Fine details are lost. A large, clear, simple drawing scores better than a small, detailed one.

**If you keep failing the same category**, look at the Google Quick Draw examples for that category — they show exactly the style the model was trained on. [quickdraw.withgoogle.com](https://quickdraw.withgoogle.com/)

**The undo button is your friend.** Made a wrong stroke? Undo immediately and redraw. Don't let bad strokes confuse the classifier.

---

## Changing Difficulty

You set difficulty per alarm in the alarm editor. You can have different alarms set to different difficulties — a gentle Easy mode alarm on weekends and Hard mode on weekday mornings.

The mercy rule resets per alarm activation — each time the alarm fires, you start fresh with the full threshold in effect.

---

## Which Mode Should You Start With?

If you're unsure, start with **Medium mode**. If you find yourself dismissing it without fully waking up after a week, switch to Hard. If you find it frustratingly difficult on certain categories, stay with Medium and work up to Hard over time.

The goal is to get your prefrontal cortex engaged before you dismiss the alarm. Medium mode reliably achieves this for most people. Hard mode is there for those who need the extra push.
