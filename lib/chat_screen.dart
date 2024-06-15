import 'dart:convert';

import 'package:charm_cherie/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:provider/provider.dart';

import 'constants.dart';

const String _apiKey = String.fromEnvironment('API_KEY');

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});



  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      
      body: SafeArea(child: ChatWidget(apiKey: _apiKey)),
    );
  }
}

class ChatWidget extends StatefulWidget {
  const ChatWidget({
    required this.apiKey,
    super.key,
  });

  final String apiKey;

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {

  late final GenerativeModel _model;
  late final ChatSession _chat;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();


  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: widget.apiKey,
    );
    _chat = _model.startChat(
        history: historyList,
        generationConfig: GenerationConfig(
          temperature: 1,
          topP: 0.95,
          topK: 64,
          maxOutputTokens: 8192,
          responseMimeType: "text/plain",
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
          SafetySetting(
              HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        ]);
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(
          milliseconds: 750,
        ),
        curve: Curves.easeOutCirc,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Access the ChatProvider instance
    ChatProvider chatProvider = Provider.of<ChatProvider>(context);
    final textFieldDecoration = InputDecoration(
      contentPadding: const EdgeInsets.all(15),
      hintText: 'Enter a prompt...',
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset(
              'assets/images/bot.png',
              height: 70,
            ),
          ),
          // an opacity of 1 is "neutral"
          Center(
            child: Text("CharmChérie💗",style:GoogleFonts.lobster(
              textStyle: const TextStyle(fontSize: 18),
            ),).animate(onPlay: (controller) => controller.repeat(reverse: true))
                .fadeIn(duration: 600.ms).tint(color: Colors.orange)
                .then(delay: 1000.ms) // baseline=800ms
                .slide().tint(color: Colors.pink),
          ),



          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                if (_apiKey.isNotEmpty) {
                  return ListView.builder(
                    controller: _scrollController,
                    itemBuilder: (context, idx) {
                      final content = chatProvider.generatedContent[idx];
                      return MessageWidget(
                        text: content.text,
                        image: content.image,
                        isFromUser: content.fromUser,
                      );
                    },
                    itemCount: chatProvider.generatedContent.length,
                  );
                } else {
                  return ListView(
                    children: const [
                      Text(
                        'No API key found. Please provide an API Key using '
                            "'--dart-define' to set the 'API_KEY' declaration.",
                      ),
                    ],
                  );
                }
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 25,
              horizontal: 15,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: true,
                    focusNode: _textFieldFocus,
                    decoration: textFieldDecoration,
                    controller: _textController,
                    onSubmitted: _sendChatMessage,
                  ),
                ),
                const SizedBox(width: 15),
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, _) {
                    return IconButton(
                      onPressed: chatProvider.loading
                          ? null
                          : () async {
                        _sendImagePrompt(_textController.text);
                      },
                      icon: Icon(
                        Icons.image,
                        color: chatProvider.loading
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, _) {
                    return chatProvider.loading
                        ? const CircularProgressIndicator()
                        : IconButton(
                      onPressed: () async {
                        _sendChatMessage(_textController.text);
                      },
                      icon: Icon(
                        Icons.send,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
                IconButton(
                  onPressed: () {
                    _resetChat();
                  },
                  icon: Icon(
                    Icons.refresh,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),

          ),
        ],
      ),
    );
  }
  void _resetChat() {
    // Clear chat content through ChatProvider
    Provider.of<ChatProvider>(context, listen: false).clearContent();
  }
  Future<void> _sendImagePrompt(String message) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      _showError('No image selected.');
      return;
    }

    try {
      // Update loading state through ChatProvider
      Provider.of<ChatProvider>(context, listen: false).setLoading(true);

      final bytes = await image.readAsBytes();
      final content = [
        Content.multi([
          TextPart(message),
          DataPart('image/jpeg', bytes),
        ])
      ];

      // Add user message to generated content
      Provider.of<ChatProvider>(context, listen: false).addContent(
        image: Image.file(File(image.path)),
        text: message,
        fromUser: true,
      );

      // Call API or perform relevant logic with _model
      var response = await _model.generateContent(content);
      var text = response.text;

      // Add API response to generated content
      Provider.of<ChatProvider>(context, listen: false).addContent(
        image: null,
        text: text,
        fromUser: false,
      );

      if (text == null) {
        _showError('No response from API.');
      } else {
        _scrollDown();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      // Clear text controller and reset focus
      _textController.clear();
      _textFieldFocus.requestFocus();

      // Update loading state through ChatProvider
      Provider.of<ChatProvider>(context, listen: false).setLoading(false);
    }
  }

  Future<void> _sendChatMessage(String message) async {
    if (message.trim().isEmpty) {
      // Show an error message or handle the case of an empty message
      return;
    }

    try {
      // Update loading state through ChatProvider
      Provider.of<ChatProvider>(context, listen: false).setLoading(true);

      // Add user message to generated content
      Provider.of<ChatProvider>(context, listen: false).addContent(
        image: null,
        text: message,
        fromUser: true,
      );

      // Call sendMessage method or perform relevant logic with _chat
      final response = await _chat.sendMessage(Content.text(message));
      final text = response.text;

      // Add API response to generated content
      Provider.of<ChatProvider>(context, listen: false).addContent(
        image: null,
        text: text,
        fromUser: false,
      );

      if (text == null) {
        _showError('No response from API.');
      } else {
        _scrollDown();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      // Clear text controller and reset focus
      _textController.clear();
      _textFieldFocus.requestFocus();

      // Update loading state through ChatProvider
      Provider.of<ChatProvider>(context, listen: false).setLoading(false);
    }
  }


  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: SingleChildScrollView(
            child: SelectableText(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }
}

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    Key? key,
    this.image,
    this.text,
    required this.isFromUser,
  }) : super(key: key);

  final Image? image;
  final String? text;
  final bool isFromUser;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      isFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isFromUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isFromUser)
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.reddit_rounded,
                  color: Colors.pink,
                ),
                iconSize: 25,
              ),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                decoration: BoxDecoration(
                  color: isFromUser
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (text != null)
                      SelectableText(
                        text!,
                        style: const TextStyle(
                          fontSize: 16.0,
                        ),
                      ),
                    if (image != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 200), // Adjust the max height as needed
                          child: Image(
                            image: image!.image,
                            fit: BoxFit.cover, // Adjust BoxFit as needed
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}



