import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class TranslateScreen extends StatelessWidget {
    final String text;
    final String originalText;
    // ignore: prefer_typing_uninitialized_variables
    final sourceLang;
    // ignore: prefer_typing_uninitialized_variables
    final targetLang;

  const TranslateScreen({super.key, required this.originalText, required this.text, required this.sourceLang, required this.targetLang,});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translated Text',),
        centerTitle: true,
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: true ,
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
        children: [
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 50.0,),
                  TextField(
                    scrollController: ScrollController(),
                    // scrollPhysics: const BouncingScrollPhysics(),
                    maxLines: 10,
                    controller: TextEditingController(text: originalText),
                    readOnly: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Original in ${sourceLang.toUpperCase()}',
                    ),
                  ),
                  const SizedBox(height: 50.0,),
                  TextField(
                    scrollController: ScrollController(),
                    // scrollPhysics: const BouncingScrollPhysics(),
                    maxLines: 10,
                    controller: TextEditingController(text: text),
                    readOnly: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Translated in ${targetLang.toUpperCase()}',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]
      ),
    );
  }
}