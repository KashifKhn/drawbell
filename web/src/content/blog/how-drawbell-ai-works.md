---
title: "How DrawBell's On-Device AI Recognizes Your Doodles"
description: "A look at the SE-ResNet model powering DrawBell — trained on 50M drawings, running entirely on your phone, with no internet required. Here's exactly how it works."
publishedDate: 2025-03-08
author: "Kashif Khan"
tags: ["AI", "TFLite", "on-device", "privacy", "machine learning"]
---

When you draw a cat on your screen at 7 AM, DrawBell's AI model has roughly 200 milliseconds to decide whether it's actually a cat. If the confidence is high enough, the alarm stops. If not, you draw again.

That decision happens entirely on your device. No internet. No server. No one ever sees what you drew. Here's how it works.

## The Dataset: Google Quick Draw

The model was trained on [Google Quick Draw](https://quickdraw.withgoogle.com/data) — a dataset of 50 million+ hand-drawn sketches across 345 categories, contributed by people playing the Quick Draw game.

What makes this dataset valuable for an alarm app is that these drawings are *quick* and *imperfect*. They were drawn in under 20 seconds by people who were rushed. They look like what someone half-asleep might produce. A Quick Draw "cat" looks like what you'd draw at 7 AM — not a fine-art rendering.

The 345 categories include everyday objects (cat, bicycle, tree, house), body parts (hand, ear, eye), vehicles, tools, animals, landmarks, and more. You can see the full list at [HuggingFace](https://huggingface.co/zarqankhn/quickdraw-345-tflite).

## The Model: SE-ResNet

The recognition model is a custom **SE-ResNet** (Squeeze-and-Excitation ResNet) with approximately 3 million parameters.

**SE-Net (Squeeze-and-Excitation Networks)** improves standard ResNets by adding a channel attention mechanism: the network learns to emphasize informative feature channels and suppress less useful ones. For drawing recognition, this matters because different parts of the drawing contribute differently to classification. The outline of a cat's ear is more informative than a random interior stroke.

Key architecture facts:
- Input: **28 × 28 grayscale** — strokes are rasterized to this resolution
- 345 output classes, one per Quick Draw category
- ~3 million parameters
- Float16 precision (TFLite export)
- Trained for **60 epochs** on Kaggle P100 GPU

The Float16 format cuts the file size roughly in half versus Float32 with negligible accuracy loss, making the model small enough to bundle inside an Android APK.

## How Your Drawing Gets Processed

When you draw on the canvas in DrawBell, the processing pipeline works like this:

1. **Stroke capture**: Each touch event is recorded as a sequence of (x, y) coordinates — a polyline, not a bitmap.

2. **Rasterization**: The strokes are rendered into a 28 × 28 grayscale image. Stroke color doesn't matter — only the shape.

3. **Pixel inversion**: Quick Draw images are white strokes on a black background. DrawBell inverts the canvas (which has black strokes on white) to match the training format.

4. **Inference**: The 28 × 28 image is passed through the TFLite model. The model outputs 345 float values (logits), one per category.

5. **Softmax**: The logits are converted to probabilities. The category with the highest probability is the top-1 prediction.

6. **Threshold check**: If the top-1 category matches the alarm prompt and the confidence exceeds the difficulty threshold (40%, 60%, or 75%), the alarm dismisses.

This entire pipeline runs in under 200ms on a mid-range Android device.

## Accuracy in Practice

On the Quick Draw test set:

- **Top-1 accuracy**: 76.19% — the model's first guess is correct 76% of the time
- **Top-3 accuracy**: 89.51% — the correct category appears in the top-3 predictions 89.5% of the time

For an alarm app, these numbers are appropriate. You are not trying to fool the model — you are cooperating with it. Draw a recognizable cat and it will recognize it. On Easy mode (top-3, 40% confidence), virtually any reasonable attempt will pass. On Hard mode (top-1, 75% confidence), you need to draw something clearly recognizable.

The model occasionally confuses visually similar categories — "cat" and "lion," "bicycle" and "motorbike." But this actually works in your favor on Easy mode: if your cat looks a bit like a lion, the alarm still dismisses.

## Why On-Device Matters

Running inference on-device rather than in the cloud has three concrete benefits:

**Privacy**: Your drawings are pixel arrays processed in memory. They are never transmitted anywhere. No server operator, no cloud provider, and no one else ever sees them.

**Reliability**: The alarm works without an internet connection. At 7 AM, with airplane mode on, in a basement — it still works.

**Speed**: No network latency. The inference happens in milliseconds on your local hardware.

The model is published on HuggingFace and the training code is open-source on GitHub if you want to verify exactly what it does and how it was trained.

## The 345 Categories

From the practical perspective of an alarm app: 345 categories means you'll rarely see the same prompt twice in a week. The prompts are chosen randomly each morning. Over a year of daily use, you might see each category once or twice.

Some categories are easier to draw than others. "Circle," "square," and "line" are trivially easy. "Helicopter," "clarinet," and "The Mona Lisa" require more effort. Hard mode pairings with difficult categories are genuinely challenging — which is exactly the point.
