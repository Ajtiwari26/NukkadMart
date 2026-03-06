# Bundled Audio Files

These audio files should be pre-generated using Sarvam TTS API and bundled with the app to avoid API calls during runtime.

## Required Files:

1. **greeting.wav** - Welcome message
   - Text: "Namaste! Bataiye aapko kya chahiye?"
   - Voice: Sarvam AI "shubh" voice
   - Language: Hindi (hi-IN)

2. **checking_stock.wav** - Filler audio during database lookup
   - Text: "Ek second, main check kar raha hun..."
   - Voice: Sarvam AI "shubh" voice
   - Language: Hindi (hi-IN)

3. **one_moment.wav** - Alternative filler audio
   - Text: "Ruko, main dekh raha hun..."
   - Voice: Sarvam AI "shubh" voice
   - Language: Hindi (hi-IN)

## How to Generate:

Use the Sarvam TTS API to generate these files:

```bash
curl -X POST https://api.sarvam.ai/text-to-speech \
  -H "api-subscription-key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "inputs": ["Namaste! Bataiye aapko kya chahiye?"],
    "target_language_code": "hi-IN",
    "speaker": "shubh",
    "pace": 1.05,
    "speech_sample_rate": 24000,
    "enable_preprocessing": true,
    "model": "bulbul:v3"
  }'
```

Save the base64 decoded audio as WAV files in this directory.

## Why Bundle Audio?

1. **Consistency**: Same voice as AI responses (Sarvam TTS)
2. **Performance**: No API latency for common phrases
3. **Reliability**: Works offline
4. **Cost**: Saves API calls
5. **UX**: Instant playback, no waiting
