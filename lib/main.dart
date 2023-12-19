import 'package:flutter/material.dart';
import 'package:google_gemini/google_gemini.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
// https://makersuite.google.com/app/apikey
const apiKey = "";


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key,});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Google Gemini"),
        centerTitle: true,
      ),
      body: const GeminiQueryWidget(),
    );
  }
}

class GeminiQueryWidget extends StatefulWidget {
  const GeminiQueryWidget({super.key,});

  @override
  State<GeminiQueryWidget> createState() => _GeminiQueryWidgetState();
}

class _GeminiQueryWidgetState extends State<GeminiQueryWidget> {
  bool loading = false;
  List chatHistory = [];
  File? imageFile;

  final ImagePicker picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _controller = ScrollController();

  // Create Gemini Instance
  final gemini = GoogleGemini(
    apiKey: apiKey,
  );

  void submitQuery() {
    String query = _textController.text.trim();
    if (query.isEmpty && imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter text or select an image"))
      );
      return;
    }

    setState(() {
      loading = true;
      chatHistory.add({
        "role": "User",
        "text": query,
        "image": imageFile != null ? File(imageFile!.path) : null,
      });
      _textController.clear();
      imageFile = null;
    });
    scrollToTheEnd();

    if (imageFile != null) {
      gemini.generateFromTextAndImages(query: query, image: File(imageFile!.path))
          .then((value) => processResponse(value.text))
          .catchError((e) => processError(e));
    } else {
      gemini.generateFromText(query)
          .then((value) => processResponse(value.text))
          .catchError((e) => processError(e));
    }
  }

  void processResponse(String response) {
    setState(() {
      loading = false;
      chatHistory.add({
        "role": "Gemini",
        "text": response,
        "image": null
      });
    });
    scrollToTheEnd();
  }

  void processError(Object error) {
    setState(() {
      loading = false;
      chatHistory.add({
        "role": "Gemini",
        "text": error.toString(),
        "image": null
      });
    });
    scrollToTheEnd();
  }

  void scrollToTheEnd() {
    if (_controller.hasClients) {
      _controller.jumpTo(_controller.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _controller,
            itemCount: chatHistory.length,
            padding: const EdgeInsets.only(bottom: 20),
            itemBuilder: (context, index) {
              var item = chatHistory[index];
              bool isUser = item["role"] == "User";
              Color avatarColor = isUser ? Colors.blue : Colors.green;
              Color textColor = isUser ? Colors.black : Colors.grey;

              return ListTile(
                isThreeLine: true,
                leading: CircleAvatar(
                  child: Text(item["role"].substring(0, 1)),
                  backgroundColor: avatarColor,
                  foregroundColor: Colors.white,
                ),
                title: Text(
                  item["role"],
                  style: TextStyle(color: textColor),
                ),
                subtitle: Text(
                  item["text"],
                  style: TextStyle(color: textColor),
                ),
                trailing: item["image"] == null
                    ? null
                    : Image.file(item["image"], width: 90,),
              );
            },
          ),
        ),
        if (imageFile != null)
          Container(
            margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
            height: 150,
            width: double.infinity,
            child: Image.file(imageFile!, fit: BoxFit.cover),
          ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: "Write a message",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_a_photo),
                onPressed: () async {
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      imageFile = File(image.path);
                    });
                  }
                },
              ),
              IconButton(
                icon: loading ? const CircularProgressIndicator() : const Icon(Icons.send),
                onPressed: submitQuery,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
