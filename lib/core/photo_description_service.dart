import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_keys.dart';

/// Result type for photo description API calls.
///
/// The calling screen can distinguish "success" from "failed, show
/// error UI" cleanly without needing to know API-specific error details.
class PhotoDescriptionResult {
  final bool success;
  final String? caption;
  final String? error;

  const PhotoDescriptionResult._({
    required this.success,
    this.caption,
    this.error,
  });

  const PhotoDescriptionResult.success(String caption)
      : this._(success: true, caption: caption);

  const PhotoDescriptionResult.failure(String error)
      : this._(success: false, error: error);
}

/// Responsible only for talking to the cloud image analysis API — no UI code,
/// no camera code.
///
/// - Accepts captured (and already-resized) image bytes
/// - Sends an authenticated request to the Groq API (Qwen 3.6 27B vision model)
/// - Enforces an explicit request timeout (per NFR-2)
/// - Exposes [getShortDescription] and [getDetailedDescription]
/// - Surfaces a clear [PhotoDescriptionResult] to the caller
class PhotoDescriptionService {
  /// Request timeout (per NFR-2: 10-15 seconds).
  static const Duration _timeout = Duration(seconds: 15);

  /// Generates a short, one-sentence description for [imageBytes].
  Future<PhotoDescriptionResult> getShortDescription(
    Uint8List imageBytes,
  ) {
    return _callApi(
      imageBytes,
      prompt: 'Describe this photo in one short simple sentence for a blind person.',
    );
  }

  /// Generates a longer object-focused description for [imageBytes].
  Future<PhotoDescriptionResult> getDetailedDescription(
    Uint8List imageBytes,
  ) {
    return _callApi(
      imageBytes,
      prompt: 'Describe this photo in detail for a blind person — objects, people, layout, and setting.',
    );
  }

  Future<PhotoDescriptionResult> _callApi(
    Uint8List imageBytes, {
    required String prompt,
  }) async {
    final endpoint = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final base64Image = base64Encode(imageBytes);

    final body = jsonEncode({
      'model': 'qwen/qwen3.6-27b',
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image'
              }
            }
          ]
        }
      ]
    });

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await http
            .post(
              endpoint,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${ApiKeys.groqApiKey}',
              },
              body: body,
            )
            .timeout(_timeout);

        return _parseResponse(response);
      } on TimeoutException {
        if (attempt == 2) {
          return const PhotoDescriptionResult.failure(
            'Request timed out. The AI service is taking too long to respond.',
          );
        }
      } catch (e) {
        if (attempt == 2) {
          return PhotoDescriptionResult.failure(
            'Network Error: $e',
          );
        }
      }
      // Wait before retrying (exponential backoff)
      await Future.delayed(Duration(seconds: attempt + 1));
    }
    
    return const PhotoDescriptionResult.failure('Network error: Max retries exceeded.');
  }

  PhotoDescriptionResult _parseResponse(http.Response response) {
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('choices')) {
          final choices = data['choices'] as List;
          if (choices.isNotEmpty) {
            final firstChoice = choices.first as Map<String, dynamic>;
            if (firstChoice.containsKey('message')) {
              final message = firstChoice['message'] as Map<String, dynamic>;
              if (message.containsKey('content')) {
                var caption = message['content'] as String;
                // Strip <think>...</think> reasoning blocks from the model output
                caption = caption.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '').trim();
                if (caption.isNotEmpty) {
                  return PhotoDescriptionResult.success(caption);
                }
              }
            }
          }
        }
      } catch (e) {
        return PhotoDescriptionResult.failure(
          'Failed to parse AI response: $e',
        );
      }

      return const PhotoDescriptionResult.failure(
        'Unexpected response format from the AI service.',
      );
    }

    // Handle error responses from the API
    String errorMessage;
    try {
      final errorData = jsonDecode(response.body);
      if (errorData is Map<String, dynamic> &&
          errorData.containsKey('error')) {
        final errorObj = errorData['error'] as Map<String, dynamic>;
        errorMessage = errorObj['message']?.toString() ?? 'HTTP ${response.statusCode}';
      } else {
        errorMessage = 'HTTP ${response.statusCode}';
      }
    } catch (_) {
      errorMessage = 'HTTP ${response.statusCode}';
    }

    switch (response.statusCode) {
      case 429:
        return const PhotoDescriptionResult.failure(
          'Rate limit reached. Please wait a moment and try again.',
        );
      case 503:
        return PhotoDescriptionResult.failure(
          'The AI service is temporarily unavailable. $errorMessage',
        );
      case 401:
      case 403:
        return const PhotoDescriptionResult.failure(
          'Authentication failed. Please check your API key.',
        );
      case 400:
        return PhotoDescriptionResult.failure(
          'Invalid request. $errorMessage',
        );
      default:
        return PhotoDescriptionResult.failure(
          'API error: $errorMessage',
        );
    }
  }
}
