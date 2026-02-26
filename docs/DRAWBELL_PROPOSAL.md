# DrawBell — Alarm App Proposal

## Overview

DrawBell is an flutter alarm app that forces the user to draw a specific doodle correctly to dismiss the alarm. Unlike existing alarm apps that are dismissed by pressing a button, shaking the phone, or solving a basic math problem, DrawBell uses an on-device AI model to recognize what you drew — if it does not match the required category, the alarm keeps ringing.

---

## Problem

Most "challenge alarm" apps (Alarmy, DoodleWake, etc.) use:

- Button press or swipe
- Barcode scanning
- Simple math problems
- Basic unverified doodles

These are either too easy or require external objects (like a barcode). A half-asleep user can dismiss them without truly waking up.

---

## Solution

DrawBell shows a random prompt such as **"Draw a cat"**. The user must draw it on the screen. The AI model — running entirely on-device — judges whether the drawing is recognizable. Only a correct, confident drawing stops the alarm.

This requires genuine cognitive engagement: the user must understand the word, plan the drawing, and execute it well enough for the AI to recognize it. It is significantly harder to do while still asleep.

---

## Key Differentiator

| Feature        | Other Apps              | DrawBell                          |
| -------------- | ----------------------- | --------------------------------- |
| Dismiss method | Button / math / barcode | Draw a specific object            |
| AI recognition | None                    | On-device TFLite model            |
| Works offline  | Varies                  | Yes — fully on-device             |
| Categories     | N/A                     | 345 object categories             |
| Difficulty     | Low                     | Adjustable (confidence threshold) |

---

## How It Works

1. User sets an alarm with a chosen difficulty level
2. Alarm fires — screen wakes up showing a random prompt (e.g. "Draw a bicycle")
3. User draws on the canvas
4. On-device AI model checks if the drawing matches the prompt
5. If confidence exceeds the threshold → alarm dismissed
6. If wrong or too low confidence → canvas clears, alarm continues

---

## AI Model

The recognition model is already trained, tested, and published.

- **Architecture:** Custom SE-ResNet (3M parameters, 28×28 grayscale input)
- **Dataset:** Google Quick Draw — 345 categories, 50M+ drawings
- **Top-1 Accuracy:** 76.19% | **Top-3 Accuracy:** 89.51%
- **Format:** TFLite float16 (8.44 MB) — runs fully on-device, no internet required
- **Training:** 60 epochs on Kaggle P100 GPU

**Model (HuggingFace):**
https://huggingface.co/zarqankhn/quickdraw-345-tflite

**Training Code & Flutter App (GitHub):**
https://github.com/KashifKhn/quickdraw-345-classifier

**Kaggle Training Notebook:**
https://www.kaggle.com/code/zarqankhn/quickdraw-345-doodle-classifier-tflite

**Refrence in Device foler:**
Main Dir: /home/zarqan-khn/mycoding/ai-ml-dl/kaggle/quickdraw-345-classifier/
App Dir: /home/zarqan-khn/mycoding/ai-ml-dl/kaggle/quickdraw-345-classifier/quickdraw_app/
Model Dir: /home/zarqan-khn/mycoding/ai-ml-dl/kaggle/quickdraw-345-classifier/model/

---

## App Details

- **Name:** DrawBell
- **Platform:** flutter (mobile)
- **Package ID:** `dev.kashifkhan.drawbell`
- **Web:** `drawbell.kashifkhan.dev`
- **Tech Stack:** Flutter + TFLite (tflite_flutter)
- **Offline:** Yes — no internet required, all inference on-device

---

## Features (Proposed)

**Core**

- Alarm scheduling (time, repeat days)
- Random category prompt on alarm trigger
- Drawing canvas with undo
- On-device AI recognition to dismiss
- Difficulty levels (Easy / Medium / Hard — adjusts confidence threshold)

**Nice to Have**

- Choose specific categories to practice
- Stats (how many attempts to dismiss, categories you struggle with)
- Custom alarm sounds
- Snooze disabled by default (optional to enable)

---

## Target Audience

- Heavy sleepers who cannot wake up with normal alarms
- Students and professionals who want to start the day with a mental warm-up
- Anyone who has dismissed an alarm half-asleep and regretted it

---

## Current Status

The core technology is complete:

- AI model trained and published
- Flutter app scaffold exists with drawing canvas and TFLite inference working
- Both pixel inversion and double-softmax bugs fixed

What remains is adding the alarm scheduling layer on top of the existing working app.
