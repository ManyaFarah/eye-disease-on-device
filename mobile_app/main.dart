import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EyeDiseaseApp());
}

String tr(bool isArabic, {required String ar, required String en}) {
  return isArabic ? ar : en;
}

class EyeDiseaseApp extends StatefulWidget {
  const EyeDiseaseApp({super.key});

  @override
  State<EyeDiseaseApp> createState() => _EyeDiseaseAppState();
}

class _EyeDiseaseAppState extends State<EyeDiseaseApp> {
  late bool _isArabic;

  @override
  void initState() {
    super.initState();

    /// اللغة الافتراضية حسب لغة الجهاز
    final systemLocale = ui.PlatformDispatcher.instance.locale;
    _isArabic = systemLocale.languageCode.toLowerCase().startsWith('ar');
  }

  void _changeLanguage(bool toArabic) {
    setState(() {
      _isArabic = toArabic;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eye Disease Classifier',
      color: const Color(0xFF5C78B3),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 222, 237, 247),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5C78B3)),
        useMaterial3: true,
      ),
      home: WelcomeScreen(
        isArabic: _isArabic,
        onLanguageChanged: _changeLanguage,
      ),
    );
  }
}

/// زر تغيير اللغة
class LanguageIconButton extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onTap;

  const LanguageIconButton({
    super.key,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.language, size: 30),
        color: const Color(0xFF5C78B3),
        tooltip: isArabic ? 'English' : 'العربية',
        onPressed: onTap,
      ),
    );
  }
}

/// شاشة ترحيبية
class WelcomeScreen extends StatelessWidget {
  final bool isArabic;
  final void Function(bool toArabic) onLanguageChanged;

  const WelcomeScreen({
    super.key,
    required this.isArabic,
    required this.onLanguageChanged,
  });

  Future<bool> _onWillPop(BuildContext context) async {
    final bool? shouldExit = await showExitDialog(context, isArabic);
    if (shouldExit == true) {
      SystemNavigator.pop();
    }
    return false;

    /// لا تخرج تلقائيًا
  }

  void _toggleLanguage() {
    onLanguageChanged(!isArabic);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white70,
                  radius: 100,
                  child: Image.asset('assets/images/Eye.jpg', height: 130),
                ),
                const SizedBox(height: 12),

                LanguageIconButton(isArabic: isArabic, onTap: _toggleLanguage),

                const SizedBox(height: 16),
                Text(
                  tr(
                    isArabic,
                    ar: 'تطبيق تصنيف أمراض العين',
                    en: 'Eye Disease Classifier',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF5C78B3),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tr(
                    isArabic,
                    ar:
                        'تطبيق تجريبي يساعد في تصنيف أمراض العين '
                        '\n(Cataract, Diabetic Retinopathy, Glaucoma, Normal) '
                        'اعتماداً على صور لقاع العين',
                    en:
                        'An experimental app that helps classify eye diseases '
                        '\n(Cataract, Diabetic Retinopathy, Glaucoma, Normal) '
                        'based on fundus images.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF3FADB5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder:
                              (_) => ClassifierScreen(
                                isArabicInit: isArabic,
                                onLanguageChanged: onLanguageChanged,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      tr(isArabic, ar: 'ابدأ', en: 'Start'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// شاشة التصنيف
class ClassifierScreen extends StatefulWidget {
  final bool isArabicInit;
  final void Function(bool toArabic) onLanguageChanged;

  const ClassifierScreen({
    super.key,
    required this.isArabicInit,
    required this.onLanguageChanged,
  });

  @override
  State<ClassifierScreen> createState() => _ClassifierScreenState();
}

class _ClassifierScreenState extends State<ClassifierScreen> {
  /// لقياس زمن الاستدلال
  double? _inferenceTimeMs;

  static const String _fp16Path = 'assets/models/model_fp16.tflite';
  static const String _drqPath = 'assets/models/model_drq.tflite';

  /// أسماء الفئات
  static const List<String> _classNames = <String>[
    'Cataract',
    'Diabetic Retinopathy',
    'Glaucoma',
    'Normal',
  ];

  Interpreter? _interpreter;
  bool _isModelLoading = true;
  File? _selectedImage;
  List<double>? _probs;
  String? _topClassName;

  late bool _isArabic;

  @override
  void initState() {
    super.initState();
    _isArabic = widget.isArabicInit;
    _loadModel();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  void _updateLanguage(bool toArabic) {
    widget.onLanguageChanged(toArabic);

    /// تحديث في التطبيق كله
    setState(() {
      _isArabic = toArabic;
    });
  }

  void _toggleLanguage() {
    _updateLanguage(!_isArabic);
  }

  /// تحميل النموذج: FP16 ثم DRQ إذا فشل
  Future<void> _loadModel() async {
    setState(() => _isModelLoading = true);

    Future<bool> tryLoad(String path, String name) async {
      try {
        final interpreter = await Interpreter.fromAsset(path);

        /// Warmup بسيط
        final input = List.generate(
          1,
          (_) => List.generate(
            224,
            (_) => List.generate(224, (_) => List.filled(3, 0.0)),
          ),
        );
        final output = List.generate(1, (_) => List.filled(4, 0.0));
        interpreter.run(input, output);

        _interpreter?.close();
        _interpreter = interpreter;
        return true;
      } catch (e) {
        debugPrint('Failed loading $name: $e');
        return false;
      }
    }

    bool ok = await tryLoad(_fp16Path, 'FP16');

    if (!ok) {
      ok = await tryLoad(_drqPath, 'DRQ');
    }

    setState(() => _isModelLoading = false);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              _isArabic,
              ar: 'فشل تحميل النموذجين. تأكد من ملفات assets والمسارات.',
              en: 'Failed to load both models. Check assets and paths.',
            ),
          ),
        ),
      );
    }
  }

  /// اختيار صورة من المعرض أو الكاميرا
  Future<void> _pickImage(ImageSource source) async {
    if (_isModelLoading) return;

    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: source);

    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
      _probs = null;
      _topClassName = null;
      _inferenceTimeMs = null;
    });
  }

  /// تحضير الصورة واستدعاء النموذج
  Future<void> _classify() async {
    if (_interpreter == null || _selectedImage == null) return;

    try {
      final Uint8List bytes = await _selectedImage!.readAsBytes();
      img.Image? original = img.decodeImage(bytes);
      if (original == null) {
        throw Exception('تعذّر قراءة الصورة');
      }

      final img.Image resized = img.copyResize(
        original,
        width: 224,
        height: 224,
      );

      final input = List.generate(
        1,
        (_) => List.generate(
          224,
          (_) => List.generate(224, (_) => List.filled(3, 0.0)),
        ),
      );

      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final img.Pixel pixel = resized.getPixel(x, y);
          input[0][y][x][0] = pixel.r.toDouble();
          input[0][y][x][1] = pixel.g.toDouble();
          input[0][y][x][2] = pixel.b.toDouble();
        }
      }

      final output = List.generate(1, (_) => List.filled(4, 0.0));
      final stopwatch = Stopwatch()..start();
      _interpreter!.run(input, output);
      stopwatch.stop();
      final elapsedMs = stopwatch.elapsedMilliseconds.toDouble();

      final List<double> probs = List<double>.from(output[0].map((e) => e));

      int maxIndex = 0;
      double maxValue = probs[0];
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > maxValue) {
          maxValue = probs[i];
          maxIndex = i;
        }
      }

      setState(() {
        _probs = probs;
        _topClassName = _classNames[maxIndex];
        _inferenceTimeMs = elapsedMs;
      });
    } catch (e) {
      debugPrint('Error during classification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                _isArabic,
                ar: 'حدث خطأ أثناء المعالجة. تأكد من أن الصورة صالحة.',
                en:
                    'An error occurred during processing. Please use a valid image.',
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmExit() async {
    final bool? shouldExit = await showExitDialog(context, _isArabic);
    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  Future<bool> _onWillPop() async {
    await _confirmExit();
    return false;

    /// لا يخرج مباشرة
  }

  @override
  Widget build(BuildContext context) {
    final bool canClassify = !_isModelLoading && _selectedImage != null;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LanguageIconButton(isArabic: _isArabic, onTap: _toggleLanguage),
              Expanded(
                child: Center(
                  child: Text(
                    _isArabic
                        ? 'تطبيق تصنيف أمراض العين'
                        : 'Eye Disease Classifier',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5C78B3),
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: _confirmExit,
                  icon: const Icon(Icons.exit_to_app),
                  color: const Color(0xFF5C78B3),
                  tooltip: tr(_isArabic, ar: 'إغلاق التطبيق', en: 'Exit app'),
                ),
              ),
            ],
          ),
        ),
        body:
            _isModelLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                tr(
                                  _isArabic,
                                  ar: 'من المعرض',
                                  en: 'From gallery',
                                ),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _pickImage(ImageSource.camera),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                tr(
                                  _isArabic,
                                  ar: 'من الكاميرا',
                                  en: 'From camera',
                                ),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      if (_selectedImage != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.file(
                            _selectedImage!,
                            height: 260,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          height: 260,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.white,
                            border: Border.all(
                              color: const Color.fromARGB(255, 224, 224, 224),
                            ),
                          ),
                          child: Text(
                            tr(
                              _isArabic,
                              ar: 'لم يتم اختيار صورة بعد',
                              en: 'No image selected yet',
                            ),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: canClassify ? _classify : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            tr(
                              _isArabic,
                              ar: 'تشخيص الصورة',
                              en: 'Classify image',
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (_probs != null && _topClassName != null)
                        _buildResultCard(),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(_isArabic, ar: ':التصنيف الأقرب', en: 'Predicted class:'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _topClassName ?? '',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 112, 168, 196),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr(
                _isArabic,
                ar: ':الاحتمالات لكل فئة',
                en: 'Class probabilities:',
              ),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...List.generate(_classNames.length, (i) {
              final double p = _probs![i];
              return Text(
                '- ${_classNames[i]}: ${(p * 100).toStringAsFixed(2)} %',
                style: const TextStyle(fontSize: 14),
              );
            }),

            if (_inferenceTimeMs != null) ...[
              const SizedBox(height: 10),
              Text(
                tr(
                  _isArabic,
                  ar:
                      'زمن الاستدلال التقريبي: '
                      '${_inferenceTimeMs!.toStringAsFixed(1)} مللي ثانية',
                  en:
                      'Approx. inference time: '
                      '${_inferenceTimeMs!.toStringAsFixed(1)} ms',
                ),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],

            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 190, 222, 237),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Directionality(
                textDirection:
                    _isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: Text(
                  _isArabic
                      ? 'تنبيه مهم:\n'
                          'هذا التطبيق أداة مساعدة فقط ولا يُعتبر بديلاً عن التشخيص الطبي '
                          'أو قرار طبيب العيون المختص.'
                      : 'Important Notice:\n'
                          'This application is an assistive tool only and is not a substitute '
                          'for professional medical diagnosis or the decision of an ophthalmologist.',
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog تأكيد الخروج
Future<bool?> showExitDialog(BuildContext context, bool isArabic) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5C78B3), Color(0xFF3FADB5)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.exit_to_app_rounded,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                tr(isArabic, ar: 'تأكيد الخروج', en: 'Confirm Exit'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tr(
                  isArabic,
                  ar: 'هل أنت متأكد أنك تريد إغلاق التطبيق؟',
                  en: 'Are you sure you want to close the app?',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white70),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(tr(isArabic, ar: 'إلغاء', en: 'Cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF5C78B3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        tr(isArabic, ar: 'خروج', en: 'Exit'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
