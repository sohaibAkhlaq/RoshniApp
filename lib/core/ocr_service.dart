import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'api_keys.dart';
import 'connectivity_service.dart';

class OcrResult {
  final bool success;
  final String text;
  final String? errorMessage;
  final String? debugImagePath;
  final bool isCloudResult;

  const OcrResult({
    required this.success,
    required this.text,
    this.errorMessage,
    this.debugImagePath,
    this.isCloudResult = false,
  });
}

class OcrService {
  Future<void> _ensureTrainedDataIsLoaded() async {
    print("OCR SERVICE: Verifying urd.traineddata is loaded correctly...");
    final appDir = await getApplicationDocumentsDirectory();
    final file = File('${appDir.path}/tessdata/urd.traineddata');
    
    if (await file.exists()) {
      final size = await file.length();
      print("OCR SERVICE: Existing urd.traineddata size is $size bytes.");
      // The high accuracy urd.traineddata in assets is ~8MB (approx 8,000,000 bytes).
      // The old 'fast' model was only 1.4MB. If it's under 5MB, delete to reload.
      if (size < 5000000) {
        print("OCR SERVICE: Found old/fast model. Deleting to force reload of the BEST model!");
        await file.delete();
      } else {
        print("OCR SERVICE: Best model is already loaded ($size bytes). Skipping copy.");
        return;
      }
    } else {
      print("OCR SERVICE: urd.traineddata not found in app directory.");
    }
  }

  /// Zero-allocation sharpness estimation using 1D pixel gradient variance.
  double _estimateSharpness(img.Image image) {
    if (image.width < 10 || image.height < 10) return 0.0;
    double sum = 0;
    double sumSq = 0;
    int count = 0;
    int i = 0;
    num prevR = 0;
    for (final p in image) {
      if (i % 5 == 0 && i > 0) {
        final diff = (p.r - prevR).abs();
        sum += diff;
        sumSq += diff * diff;
        count++;
      }
      prevR = p.r;
      i++;
    }
    if (count == 0) return 0.0;
    final mean = sum / count;
    return (sumSq / count) - (mean * mean);
  }

  /// Try calling Cloud AI Vision OCR (UTRNet-style Nastaliq extraction) if online.
  Future<String?> _tryCloudOcr(Uint8List imageBytes) async {
    try {
      final connectivity = ConnectivityService();
      if (!await connectivity.hasInternet()) {
        print("OCR SERVICE: Device is offline. Skipping Cloud OCR.");
        return null;
      }

      print("OCR SERVICE: Online! Calling Cloud Urdu OCR Service for high-accuracy Nastaliq recognition...");
      final endpoint = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final base64Image = base64Encode(imageBytes);
      const prompt =
          "You are an expert Pakistani Urdu linguistic OCR engine. Your task is to accurately read and transcribe all Urdu text visible in this image (from books, documents, signboards, or notes) for a blind user.\n\n"
          "CRITICAL INSTRUCTIONS FOR 100% ACCURACY:\n"
          "1. Transcribe the Urdu text in clean Urdu script (Nastaliq/Naskh).\n"
          "2. Word & Sentence Cohesion: In Urdu Nastaliq script, dots (نقاط) and curves can appear stylized or faint in camera photos. Use Pakistani Urdu grammatical and linguistic context to correctly recognize words so that the sentences are meaningful, coherent, and grammatically accurate exactly as written in the text. Never leave out words or fragment sentences due to minor image noise.\n"
          "3. Factual Fidelity (Zero Hallucination): Do NOT invent, summarize, or add any sentences/paragraphs that are not written in the image. Transcribe faithfully only what is written.\n"
          "4. Output ONLY the Urdu transcription in Urdu script. Do NOT include any English words, translations, explanations, markdown formatting, or <think> tags.\n"
          "5. If there is absolutely no readable text in the image, output exactly: NO_TEXT_FOUND";

      final body = jsonEncode({
        'model': 'qwen/qwen3.6-27b',
        'temperature': 0.0,
        'max_tokens': 1024,
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

      final response = await http
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${ApiKeys.groqApiKey}',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('choices')) {
          final choices = data['choices'] as List;
          if (choices.isNotEmpty) {
            final firstChoice = choices.first as Map<String, dynamic>;
            if (firstChoice.containsKey('message')) {
              final message = firstChoice['message'] as Map<String, dynamic>;
              if (message.containsKey('content')) {
                var text = message['content'] as String;
                text = text.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '').trim();
                text = text.replaceAll(RegExp(r'```[a-zA-Z]*\n?'), '').replaceAll('```', '').trim();
                if (text.isNotEmpty &&
                    text.length >= 2 &&
                    !text.toLowerCase().contains("no_text_found") &&
                    !text.toLowerCase().contains("no text")) {
                  print("OCR SERVICE: Cloud OCR Success! Extracted: [$text]");
                  return text;
                }
              }
            }
          }
        }
      }
      print("OCR SERVICE: Cloud OCR returned empty or non-200 (${response.statusCode}). Falling back to local OCR.");
      return null;
    } catch (e) {
      print("OCR SERVICE: Cloud OCR error/timeout ($e). Falling back to local on-device Tesseract OCR.");
      return null;
    }
  }

  Future<OcrResult> recognizeText(String imagePath) async {
    try {
      print("OCR SERVICE: =========================================");
      print("OCR SERVICE: Starting Advanced Hybrid Urdu OCR on $imagePath");
      print("OCR SERVICE: =========================================");

      // 1. Read raw bytes
      final imageBytes = await File(imagePath).readAsBytes();
      if (imageBytes.isEmpty) {
        return const OcrResult(success: false, text: '', errorMessage: 'Image is empty.');
      }

      // 2. Preprocess image for Cloud OCR (Bake EXIF orientation so Nastaliq is upright & resize if too large)
      Uint8List cloudImageBytes = imageBytes;
      try {
        var decodedImg = img.decodeImage(imageBytes);
        if (decodedImg != null) {
          decodedImg = img.bakeOrientation(decodedImg);
          final maxDim = max(decodedImg.width, decodedImg.height);
          if (maxDim > 1600) {
            final scale = 1600 / maxDim;
            decodedImg = img.copyResize(
              decodedImg,
              width: (decodedImg.width * scale).round(),
              height: (decodedImg.height * scale).round(),
              interpolation: img.Interpolation.linear,
            );
          }
          cloudImageBytes = Uint8List.fromList(img.encodeJpg(decodedImg, quality: 88));
          print("OCR SERVICE: Baked orientation and prepared Cloud OCR image: ${decodedImg.width}x${decodedImg.height}");
        }
      } catch (e) {
        print("OCR SERVICE: Could not preprocess image for cloud ($e), sending raw bytes.");
      }

      // STEP 1 — HYBRID CLOUD OCR ATTEMPT (If Online)
      // Gives human-level accuracy on complex Nastaliq signage without phone CPU/memory strain.
      final cloudText = await _tryCloudOcr(cloudImageBytes);
      if (cloudText != null && cloudText.isNotEmpty) {
        print("OCR SERVICE: Returning high-accuracy Cloud OCR result!");
        return OcrResult(
          success: true,
          text: cloudText,
          debugImagePath: imagePath,
          isCloudResult: true,
        );
      }

      print("OCR SERVICE: Proceeding to offline on-device Tesseract OCR fallback...");

      // 3. Verify Language File for Offline OCR
      await _ensureTrainedDataIsLoaded();

      // 4. Decode and check raw image for local preprocessing
      var processedImage = img.decodeImage(imageBytes);
      if (processedImage == null) {
        return const OcrResult(success: false, text: '', errorMessage: 'Failed to read image pixels.');
      }
      
      print("OCR SERVICE: Raw Decoded Dimensions: ${processedImage.width}x${processedImage.height}");

      // 5. STEP 3.4 — Orientation Fix (Bake EXIF)
      processedImage = img.bakeOrientation(processedImage);
      print("OCR SERVICE: Baked orientation. New Dimensions: ${processedImage.width}x${processedImage.height}");

      // STEP 3.3 — Sharpness / Blur Detection (Zero allocation)
      final sharpness = _estimateSharpness(processedImage);
      print("OCR SERVICE: Sharpness / Blur Variance Score: ${sharpness.toStringAsFixed(1)}");
      if (sharpness < 20.0) {
        print("OCR SERVICE WARNING: Image appears blurry! Fine Urdu details may be lost.");
      }

      // STEP 3.1 — Smart Resizing (Check LONGEST dimension to avoid memory bloat)
      final maxDim = max(processedImage.width, processedImage.height);
      if (maxDim < 1000) {
        final oldW = processedImage.width;
        final oldH = processedImage.height;
        processedImage = img.copyResize(
          processedImage, 
          width: (processedImage.width * 1.5).round(), 
          interpolation: img.Interpolation.cubic,
        );
        print("OCR SERVICE: Upscaled small image from ${oldW}x${oldH} to ${processedImage.width}x${processedImage.height} (Cubic)");
      } else if (maxDim > 2000) {
        final oldW = processedImage.width;
        final oldH = processedImage.height;
        final scale = 1800.0 / maxDim;
        processedImage = img.copyResize(
          processedImage, 
          width: (processedImage.width * scale).round(), 
          interpolation: img.Interpolation.linear,
        );
        print("OCR SERVICE: Downscaled large image from ${oldW}x${oldH} to ${processedImage.width}x${processedImage.height} to prevent OOM.");
      } else {
        print("OCR SERVICE: Image resolution (${processedImage.width}x${processedImage.height}) is optimal for OCR. Skipping resize.");
      }

      // STEP 3.2 — Clean Grayscale & Contrast Normalization
      // NOTE: We do NOT use hard binarization (luminanceThreshold) because it wipes out thin Urdu dots (nuqtas) and joining strokes!
      // Instead, we normalize dynamic range across 0..255 and apply a gentle contrast boost (1.25), letting Tesseract's native C++ Otsu engine do adaptive binarization!
      print("OCR SERVICE: Converting to grayscale, normalizing contrast, and boosting sharpness...");
      processedImage = img.grayscale(processedImage);
      processedImage = img.normalize(processedImage, min: 0, max: 255);
      processedImage = img.adjustColor(processedImage, contrast: 1.25);

      // STEP 1 — Save preprocessed debug image for visual inspection
      final tempDir = await getTemporaryDirectory();
      final fixedPath = '${tempDir.path}/simple_ocr_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final encodedJpg = img.encodeJpg(processedImage, quality: 95);
      await File(fixedPath).writeAsBytes(encodedJpg);
      print("OCR SERVICE: Saved Tesseract input image to $fixedPath");

      // Also try saving to public Downloads folder for easy user retrieval
      String? publicDebugPath;
      try {
        final pubDir = Directory('/storage/emulated/0/Download');
        if (await pubDir.exists()) {
          publicDebugPath = '/storage/emulated/0/Download/roshni_ocr_debug.jpg';
          await File(publicDebugPath).writeAsBytes(encodedJpg);
          print("OCR SERVICE: [STEP 1 DEBUG] Saved copy to $publicDebugPath - Open in Files/Gallery to inspect!");
        }
      } catch (e) {
        print("OCR SERVICE: Could not save to public Downloads: $e");
      }

      // 6. STEP 2 — Test Multiple Signboard PSM Modes with LSTM (OEM 1)
      // PSM 7: Single line of text (best for signboards/labels)
      // PSM 6: Uniform block of text
      // PSM 3: Automatic page segmentation
      print("OCR SERVICE: Testing Signboard PSM Modes (7: Single Line, 6: Block, 3: Auto) with OEM 1 (LSTM)...");
      
      final results = <int, String>{};
      for (final psm in [7, 6, 3]) {
        final res = await FlutterTesseractOcr.extractText(
          fixedPath,
          language: 'urd',
          args: {
            "tessedit_pageseg_mode": "$psm",
            "tessedit_ocr_engine_mode": "1", // 1 = Neural nets LSTM engine only
          },
        );
        results[psm] = res.trim();
        print("OCR SERVICE: [PSM $psm] Result: [${results[psm]}]");
      }

      try { await File(fixedPath).delete(); } catch (_) {}

      // Prefer PSM 7 (single line) or PSM 6 (block) if they found meaningful Urdu text (>= 3 chars)
      String bestText = '';
      if ((results[7]?.length ?? 0) >= 3) {
        bestText = results[7]!;
      } else if ((results[6]?.length ?? 0) >= 3) {
        bestText = results[6]!;
      } else {
        bestText = results[3] ?? '';
      }
      
      if (bestText.isEmpty || bestText.length < 3) {
        print("OCR SERVICE: All PSM modes produced empty/short text. Returning fallback.");
        return OcrResult(
          success: false, 
          text: '', 
          errorMessage: 'No readable text found. Try holding camera closer or steadier.',
          debugImagePath: publicDebugPath ?? fixedPath,
        );
      }

      print("OCR SERVICE: Success! Best Text Selected: $bestText");
      return OcrResult(
        success: true, 
        text: bestText,
        debugImagePath: publicDebugPath ?? fixedPath,
        isCloudResult: false,
      );

    } catch (e, stack) {
      print("OCR SERVICE: FATAL EXCEPTION CAUGHT: $e");
      print(stack);
      return OcrResult(
        success: false, 
        text: '', 
        errorMessage: 'OCR Processing crashed: $e',
      );
    }
  }
}
