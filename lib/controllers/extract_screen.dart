import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:ocr_app/controllers/translate_screen.dart';
import 'package:share_plus/share_plus.dart';

class ExtractionScreen extends StatelessWidget {
  final String text;

  const ExtractionScreen({super.key, required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extracted Text'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pop(context);
          }, 
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              await Share.share(text);
            }, 
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Text copied to clipboard.'),
                ),
              );
            }, 
          ),],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [ 
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: TextField(
              scrollController: ScrollController(),
                  // scrollPhysics: const BouncingScrollPhysics(),
                  maxLines: 20,
                  controller: TextEditingController(text: text),
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Extracted Text',
                  ),
                ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                backgroundColor: Colors.blue,
                shape: const CircleBorder(),
                tooltip: 'Translate text',
                child: const Icon(Icons.translate),
                onPressed: () async {
                  // ignore: unnecessary_null_comparison
                  if (text == null) return;
                  _translateText(context, text);
                }, 
              ),
            ],
          ),
        ]
      ),
    );
  }

  static Future<void> _translateText(BuildContext context, String recognizedText) async {

    final navigator = Navigator.of(context);
    LanguageIdentifier? langIdentifier;

    try {
      final langIdentifier = GoogleMlKit.nlp.languageIdentifier(confidenceThreshold: 0.5);
      final String languageCode = await langIdentifier.identifyLanguage(recognizedText);
      final TranslateLanguage sourceLang = TranslateLanguage.values.firstWhere(
        (element) => element.bcpCode == languageCode
      );
      await langIdentifier.close();
      
      final langs = await Devicelocale.preferredLanguages;
      final String devicelanguageCode = langs!.first.toString().substring(0,2);
      final TranslateLanguage targetLang = TranslateLanguage.values.firstWhere(
        (element) => element.bcpCode == devicelanguageCode
      );

      if (languageCode.compareTo(targetLang.bcpCode) == 0) {
        await navigator.push(
          MaterialPageRoute(
            builder: (context) => TranslateScreen(originalText: recognizedText, text: recognizedText, sourceLang: sourceLang, targetLang: targetLang,),
          ),
        );
      } else {
        final translator = OnDeviceTranslator(
          sourceLanguage: sourceLang, 
          targetLanguage: targetLang
        );
        final translatedText = await translator.translateText(recognizedText);
        await translator.close();
        await navigator.push(
          MaterialPageRoute(
            builder: (context) => TranslateScreen(originalText: recognizedText, text: translatedText, sourceLang: sourceLang, targetLang: targetLang,),
          ),
        );
      }
      
    } catch (e) {
      // ignore: avoid_print
      print('Error: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occured when identifying language.'),
        ),
      );
    } finally {
      // ignore: unnecessary_null_comparison
      if (langIdentifier != null) {
        langIdentifier.close();
      }
    }

  }
}