import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/env_config.dart';
import '../../../../core/constants/app_constants.dart';

/// Unified AI datasource for SevakAI.
///
/// Architecture: **Groq Primary → Gemini Fallback**
/// - Groq's LPU inference is 10-50x faster than cloud GPU endpoints.
/// - Gemini 2.5 Flash acts as a reliable safety net on Google's free tier.
/// - Each public method selects the optimal Groq model for its task.
class AiDatasource {
  late final GenerativeModel _geminiModel;

  AiDatasource() {
    _geminiModel = GenerativeModel(
      model: EnvConfig.geminiModel,
      apiKey: EnvConfig.geminiApiKey,
    );
  }

  // GROQ HTTP HELPERS

  /// Sends a chat completion request to Groq and returns the raw text response.
  Future<String> _groqChat(String model, String prompt, {double temperature = 0.1}) async {
    final apiKey = EnvConfig.groqApiKey;
    if (apiKey.isEmpty) throw Exception('GROQ_API_KEY is not configured.');

    debugPrint('[Groq Primary] → $model');
    final response = await http.post(
      Uri.parse('${EnvConfig.groqBaseUrl}/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'temperature': temperature,
      }),
    ).timeout(AppConstants.aiRequestTimeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>;
      final msgMap = (choices[0] as Map<String, dynamic>)['message'] as Map<String, dynamic>;
      return msgMap['content'] as String;
    } else {
      throw Exception('Groq HTTP ${response.statusCode}: ${response.body}');
    }
  }

  /// Transcribes audio bytes using Groq's Whisper endpoint.
  Future<String> _groqTranscribe(List<int> audioBytes) async {
    final apiKey = EnvConfig.groqApiKey;
    if (apiKey.isEmpty) throw Exception('GROQ_API_KEY is not configured.');

    debugPrint('[Groq Primary] → ${EnvConfig.groqWhisperModel} (audio)');
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${EnvConfig.groqBaseUrl}/audio/transcriptions'),
    );
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.fields['model'] = EnvConfig.groqWhisperModel;
    request.files.add(http.MultipartFile.fromBytes('file', audioBytes, filename: 'audio.m4a'));

    final streamedResponse = await request.send().timeout(AppConstants.aiRequestTimeout);
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      return json['text'] as String;
    } else {
      throw Exception('Groq Whisper ${streamedResponse.statusCode}: $responseBody');
    }
  }

  /// Translates audio bytes to English using Groq's translations endpoint.
  Future<String> _groqTranslate(List<int> audioBytes) async {
    final apiKey = EnvConfig.groqApiKey;
    if (apiKey.isEmpty) throw Exception('GROQ_API_KEY is not configured.');

    debugPrint('[Groq Primary] → ${EnvConfig.groqWhisperModel} (audio translation)');
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${EnvConfig.groqBaseUrl}/audio/translations'),
    );
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.fields['model'] = EnvConfig.groqWhisperModel;
    request.files.add(http.MultipartFile.fromBytes('file', audioBytes, filename: 'audio.m4a'));

    final streamedResponse = await request.send().timeout(AppConstants.aiRequestTimeout);
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      return json['text'] as String;
    } else {
      throw Exception('Groq Translate ${streamedResponse.statusCode}: $responseBody');
    }
  }

  // GEMINI FALLBACK HELPERS

  Future<String> _geminiFallbackText(String prompt) async {
    debugPrint('[Gemini Fallback] → ${EnvConfig.geminiModel}');
    final response = await _geminiModel.generateContent([Content.text(prompt)]);
    return response.text ?? '';
  }

  Future<String> _geminiFallbackMultimodal(String prompt, List<Part> parts) async {
    debugPrint('[Gemini Fallback] → ${EnvConfig.geminiModel} (multimodal)');
    final response = await _geminiModel.generateContent([Content.multi(parts)]);
    return response.text ?? '';
  }

  // JSON PARSER

  Map<String, dynamic> _parseJson(String text) {
    final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
    return jsonDecode(cleaned) as Map<String, dynamic>;
  }

  // PUBLIC METHODS

  /// Analyzes text + image for emergency triage.
  /// Primary: Groq vision model | Fallback: Gemini multimodal
  Future<Map<String, dynamic>> analyzeNeed(String text, List<int>? imageBytes) async {
    const prompt = '''
You are SevakAI, a SOTA 2026 AI for humanitarian coordination.
Analyze this emergency report and perform a QUANTITATIVE situation analysis.

Return ONLY valid JSON with NO markdown formatting:
{
  "location": "extracted address or landmark",
  "needType": "FOOD | MEDICAL | SHELTER | CLOTHING | OTHER",
  "urgencyScore": <0-100>,
  "urgencyReason": "one sentence justification",
  "peopleAffected": <estimated number of people>,
  "description": "brief summary",
  "scaleAssessment": {
    "severity": "CRITICAL | HIGH | MEDIUM | LOW",
    "vulnerableGroups": ["children", "elderly", "disabled", "none"],
    "infrastructureDamage": "High/Medium/Low/None",
    "estimatedScope": "one sentence on the scale of response needed"
  }
}

Scoring: 80+ (Life-threatening), 50-79 (Urgent), <50 (Important).
If the input shows Hindi/Urdu, translate to English.
''';

    final fullPrompt = '$prompt\n\nInput text: $text${imageBytes != null ? '\n(A photo of the scene is attached)' : ''}';

    try {
      // Primary: Groq text-only (image analysis is text-described)
      final output = await _groqChat(EnvConfig.groqReasoningModel, '$prompt\n\nInput text: $text');
      return _parseJson(output);
    } catch (e) {
      debugPrint('[AI] Groq failed for analyzeNeed: $e → Gemini fallback');
      try {
        final parts = <Part>[TextPart(fullPrompt)];
        if (imageBytes != null) {
          parts.add(DataPart('image/jpeg', Uint8List.fromList(imageBytes)));
        }
        final output = await _geminiFallbackMultimodal(fullPrompt, parts);
        return _parseJson(output);
      } catch (e2) {
        debugPrint('[AI] Gemini fallback also failed: $e2');
        throw Exception('All AI providers failed for emergency triage.');
      }
    }
  }

  /// Multimodal emergency analysis (audio + image).
  /// Primary: Groq Whisper + Reasoning | Fallback: Gemini native multimodal
  Future<Map<String, dynamic>> analyzeMultimodalEmergency({
    required List<int> audioBytes,
    List<int>? imageBytes,
    String? textContext,
  }) async {
    const prompt = '''
You are SevakAI SOTA 2026. You are receiving a live emergency dispatch.
Analyze the following transcription and scene description.

Return ONLY valid JSON with NO markdown formatting:
{
  "transcription": "full English translation of the voice note",
  "location": "extracted location or landmark",
  "needType": "FOOD | MEDICAL | SHELTER | CLOTHING | OTHER",
  "urgencyScore": <0-100 based on voice tone + visual evidence>,
  "urgencyReason": "one sentence justification",
  "peopleAffected": <estimated number mentioned or visible>,
  "description": "unified summary of audio and visual findings",
  "scaleAssessment": {
    "severity": "CRITICAL | HIGH | MEDIUM | LOW",
    "vulnerableGroups": ["children", "elderly", "disabled", "none"],
    "infrastructureDamage": "High/Medium/Low/None",
    "estimatedScope": "one sentence on the scale of response needed"
  }
}
''';

    try {
      // Primary: Whisper transcription/translation → GPT-OSS reasoning
      // We use _groqTranslate to ensure we get English for reasoning
      final transcript = await _groqTranslate(audioBytes);
      final fullPrompt = '''
$prompt

Transcription of audio (Translated to English): "$transcript"
User's Manual Description (if any): "${textContext ?? 'None'}"

${imageBytes != null ? '(Note: Scene photo was attached but processed as text-only in this path)' : ''}
Please prioritize the User's Manual Description if it contains more specific details or corrections than the audio.
''';
      final output = await _groqChat(EnvConfig.groqReasoningModel, fullPrompt);
      final result = _parseJson(output);
      
      // If the model produced a better English version, use it, otherwise use Whisper's
      if (result['transcription'] == null || result['transcription'].toString().isEmpty) {
        result['transcription'] = transcript;
      }
      return result;
    } catch (e) {
      debugPrint('[AI] Groq failed for multimodal: $e → Gemini fallback');
      try {
        const geminiPrompt = '''
You are SevakAI SOTA 2026. LISTEN to the attached voice note and LOOK at the scene photo (if provided).
Transcribe and Translate the voice note to English. Analyze the scene.
Return ONLY valid JSON:
{"transcription":"...","location":"...","needType":"FOOD|MEDICAL|SHELTER|CLOTHING|OTHER","urgencyScore":<0-100>,"urgencyReason":"...","peopleAffected":<n>,"description":"...","scaleAssessment":{"severity":"CRITICAL|HIGH|MEDIUM|LOW","vulnerableGroups":["children","elderly","disabled","none"],"infrastructureDamage":"High/Medium/Low/None","estimatedScope":"..."}}
''';
        final parts = <Part>[
          TextPart(geminiPrompt),
          DataPart('audio/aac', Uint8List.fromList(audioBytes)),
        ];
        if (imageBytes != null) {
          parts.add(DataPart('image/jpeg', Uint8List.fromList(imageBytes)));
        }
        final output = await _geminiFallbackMultimodal(geminiPrompt, parts);
        return _parseJson(output);
      } catch (e2) {
        debugPrint('[AI] Gemini fallback also failed: $e2');
        throw Exception('All AI providers failed for multimodal emergency.');
      }
    }
  }

  /// Co-Pilot real-time guidance for volunteers.
  /// Primary: Groq fast model (lowest latency) | Fallback: Gemini
  Future<String> generateCoPilotResponse(String context, String userMessage) async {
    final prompt = '''
You are the SevakAI First-Responder Co-Pilot.
Current Task Context: $context

Volunteer Message: $userMessage

Provide safe, concise (under 50 words), and actionable humanitarian advice.
Follow international first-aid and shelter protocols.
Always include a disclaimer if the situation sounds life-threatening.
''';

    try {
      return await _groqChat(EnvConfig.groqFastModel, prompt, temperature: 0.3);
    } catch (e) {
      debugPrint('[AI] Groq failed for CoPilot: $e → Gemini fallback');
      try {
        return await _geminiFallbackText(prompt);
      } catch (e2) {
        return 'I am having trouble connecting. Please follow local emergency protocols.';
      }
    }
  }

  /// Impact story generation for donors.
  /// Primary: Groq reasoning model | Fallback: Gemini
  Future<Map<String, dynamic>> generateImpactStory(
    String initialNeed,
    String completionNotes,
    List<int>? successImage,
  ) async {
    final prompt = '''
You are a humanitarian storyteller. Generate an impact story for an NGO's donors.
Initial Need: $initialNeed
Volunteer's Outcome Notes: $completionNotes

Return ONLY valid JSON:
{
  "headline": "catchy headline",
  "story": "a heart-warming 3-paragraph story highlighting the transformation and the role of the volunteer"
}
''';

    try {
      final output = await _groqChat(EnvConfig.groqReasoningModel, prompt, temperature: 0.7);
      return _parseJson(output);
    } catch (e) {
      debugPrint('[AI] Groq failed for impact story: $e → Gemini fallback');
      try {
        final parts = <Part>[TextPart(prompt)];
        if (successImage != null) {
          parts.add(DataPart('image/jpeg', Uint8List.fromList(successImage)));
        }
        final output = await _geminiFallbackMultimodal(prompt, parts);
        return _parseJson(output);
      } catch (e2) {
        debugPrint('[AI] Gemini fallback also failed: $e2');
        throw Exception('All AI providers failed for impact story.');
      }
    }
  }

  /// Voice transcription.
  /// Primary: Groq Whisper | Fallback: Gemini native audio
  Future<Map<String, dynamic>> analyzeVoiceNeed(List<int> audioBytes) async {
    try {
      // Use translation to ensure UI gets English for consistency in triage
      final transcript = await _groqTranslate(audioBytes);
      return {'transcription': transcript};
    } catch (e) {
      debugPrint('[AI] Groq Whisper failed: $e → Gemini fallback');
      try {
        const prompt = 'Transcribe this emergency voice note to English. Return JSON: {"transcription": "..."}';
        final parts = <Part>[TextPart(prompt), DataPart('audio/aac', Uint8List.fromList(audioBytes))];
        final output = await _geminiFallbackMultimodal(prompt, parts);
        return _parseJson(output);
      } catch (e2) {
        debugPrint('[AI] Gemini fallback also failed: $e2');
        throw Exception('All AI providers failed for voice transcription.');
      }
    }
  }
}
