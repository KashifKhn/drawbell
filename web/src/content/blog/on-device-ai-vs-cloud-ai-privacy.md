---
title: "On-Device AI vs Cloud AI: Why Your Alarm Data Should Never Leave Your Phone"
description: "Most AI apps quietly send your data to remote servers. DrawBell runs its entire AI model on your phone — no network, no logs, nothing transmitted. Here's why that distinction matters and how it works."
publishedDate: 2026-03-10
author: "Kashif Khan"
tags: ["privacy", "on-device AI", "TFLite", "cloud AI", "Android", "data privacy"]
image: "/images/blog/on-device-vs-cloud-ai.jpg"
---

Every time you interact with an AI feature on your phone, a decision was made before you ever opened the app: does the AI run *on your device*, or does your data travel to a server somewhere and come back with an answer?

That decision has real consequences — for your privacy, your reliability, and the speed of the response. Most apps make the cloud choice by default. DrawBell makes the opposite choice deliberately.

## What Cloud AI Actually Means

When an app uses cloud AI, here is what happens every time you trigger that feature:

1. Your data — a voice recording, a photo, a drawing — is packaged and sent over the network to a remote server.
2. The server runs the AI model and returns a result.
3. Your app shows you that result.

This works well when you have a fast connection. But the data leaves your device. It passes through your carrier's network. It lands on a server owned by a company (or rented from AWS, Google Cloud, or Azure). It may be logged for debugging. It may be used to retrain the model. It may be retained under a terms-of-service clause you agreed to without reading.

None of this is inherently malicious. Cloud AI is practical and often the right choice. But for something as intimate as your morning routine — the first moments of your day, captured as drawings on a screen — the cloud model asks you to trust a lot of unknown infrastructure.

## What On-Device AI Means

On-device AI runs the model directly on your phone's processor. Your data is processed in RAM and never leaves the device. There is no network call. There is no server to breach. There is no company that could receive a legal demand for your data, because they never had it.

The tradeoff historically has been quality. Larger, more accurate models require significant compute — more than a phone could provide without overheating or draining the battery in minutes.

That tradeoff has narrowed substantially over the past several years. Modern phones have dedicated neural processing units (NPUs). Quantized model formats like TFLite reduce a model's memory footprint by 50-75% with minimal accuracy loss. A model that once required a GPU cluster to run can now run on a mid-range Android phone in under 200 milliseconds.

## How DrawBell Does It

DrawBell bundles an 8.44 MB TFLite model directly inside the APK. When you draw on the screen, the inference happens on your device. The model never calls home.

The model is a **SE-ResNet** (Squeeze-and-Excitation ResNet) with approximately 3 million parameters, exported in Float16 precision. Here is what that means in practice:

| Property | Value |
|---|---|
| Architecture | SE-ResNet |
| Parameters | ~3 million |
| Format | TFLite Float16 |
| Model file size | 8.44 MB |
| Input resolution | 28 × 28 grayscale |
| Output classes | 345 categories |
| Top-1 accuracy | 76.19% |
| Top-3 accuracy | 89.51% |
| Training data | 50M+ Quick Draw sketches |
| Inference time | < 200ms on mid-range Android |

Float16 precision cuts the file size roughly in half compared to Float32, with negligible accuracy loss on this type of classification task. The 28 × 28 input resolution is deliberately small — it matches the Quick Draw training format and keeps inference fast without sacrificing accuracy.

The model was trained on [Google Quick Draw](https://quickdraw.withgoogle.com/data) — a dataset of 50 million hand-drawn sketches contributed by real people under time pressure, which makes it well-suited to recognizing the kind of quick, imperfect drawings someone makes half-asleep at 7 AM.

## The Three Practical Benefits

### 1. Your drawings are genuinely private

The drawings you make to dismiss an alarm are transient data — pixel arrays that exist in memory for the duration of inference and are then discarded. No network packet is formed. No log entry is written to a remote server. The images are never stored anywhere, not even on your own device.

This is not a privacy policy promise. It is an architectural fact: the network call simply does not exist in the codebase.

### 2. The alarm works without internet

Cloud AI has a silent dependency: a working network connection. If your phone is on airplane mode, in a basement with no signal, or if the API endpoint the app relies on is temporarily down, the feature fails.

DrawBell has no network dependency for alarm dismissal. The model is on your device. It works in airplane mode. It works with no SIM card. It works during a network outage.

For an alarm app — software you depend on to wake up — reliability under degraded conditions is not a nice-to-have. It is a basic requirement.

### 3. Inference is immediate

A cloud AI round-trip involves: compressing your data, opening a network socket, transmitting to the server, waiting for the server to run inference, receiving the response, and parsing it. Even on a fast connection, this adds 300–1500ms of latency.

On-device inference skips all of that. DrawBell's model runs in under 200ms on a mid-range Android device — fast enough that the result appears before your hand has left the screen.

## The Model Is Open

The SE-ResNet model is published on [HuggingFace](https://huggingface.co/zarqankhn/quickdraw-345-tflite) and the training code is open-source on [GitHub](https://github.com/KashifKhn/quickdraw-345-classifier). You can download the `.tflite` file, load it yourself, and verify exactly what it does. There is no hidden layer in this system.

This matters because "we process everything on-device" is a claim that can be made falsely. The open model means you can verify the claim rather than trusting it.

## When Cloud AI Is the Right Choice

On-device AI is not always better. Cloud AI makes sense when:

- The model is too large to run on a phone (GPT-4, Gemini Ultra, Stable Diffusion at full resolution)
- The feature genuinely requires up-to-date information (weather, search, live translation)
- The accuracy difference is significant enough to justify the tradeoff

DrawBell's task — recognizing one of 345 sketch categories from a 28 × 28 grayscale image — does not require a large model. A 3-million-parameter SE-ResNet is sufficient. The 8.44 MB file fits comfortably in an APK. The accuracy is appropriate for the use case. There is no reason to add a network dependency.

The cloud default in mobile AI is partly a business model, not purely a technical necessity. On-device inference means no API usage data, no server costs, no opportunity to monetize the inference logs. For an open-source alarm app with no business model to protect, that calculus points clearly toward keeping everything on the device.

## Summary

The next time an app tells you it uses AI, it is worth asking: where does that AI actually run? For DrawBell, the answer is unambiguous — on your phone, every time, with no exceptions. The model is embedded in the APK, the inference happens in RAM, and nothing is transmitted anywhere.

That is not a feature that was added. It is how the app was designed from the start.
