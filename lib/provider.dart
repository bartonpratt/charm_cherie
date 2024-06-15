import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChatProvider with ChangeNotifier {
  bool _loading = false;
  final TextEditingController _textController = TextEditingController();
  final List<_ContentItem> _generatedContent = <_ContentItem>[];

  bool get loading => _loading;
  TextEditingController get textController => _textController;
  List<_ContentItem> get generatedContent => _generatedContent;

  ChatProvider() {
    _loadContentFromPrefs();
  }

  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void addContent({Image? image, String? text, bool fromUser = false}) {
    _generatedContent.add(_ContentItem(image: image, text: text, fromUser: fromUser));
    notifyListeners();
    _saveContentToPrefs();
  }

  void clearContent() {
    _generatedContent.clear();
    _textController.clear();
    _loading = false;
    notifyListeners();
    _saveContentToPrefs();
  }

  Future<void> _saveContentToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> contentList = _generatedContent.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('chat_content', contentList);
  }

  Future<void> _loadContentFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? contentList = prefs.getStringList('chat_content');
    if (contentList != null) {
      _generatedContent.addAll(contentList.map((item) => _ContentItem.fromJson(jsonDecode(item))).toList());
      notifyListeners();
    }
  }
}

class _ContentItem {
  final Image? image;
  final String? text;
  final bool fromUser;

  _ContentItem({this.image, this.text, this.fromUser = false});

  Map<String, dynamic> toJson() {
    return {
      'image': image != null ? image!.image.toString() : null,
      'text': text,
      'fromUser': fromUser,
    };
  }

  factory _ContentItem.fromJson(Map<String, dynamic> json) {
    return _ContentItem(
      image: json['image'] != null ? Image.network(json['image']) : null,
      text: json['text'],
      fromUser: json['fromUser'],
    );
  }
}
