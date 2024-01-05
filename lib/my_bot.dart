import 'dart:convert';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ChatBot extends StatefulWidget {
  const ChatBot({super.key});

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  //add api key at the end
  final geminiProVision =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=API_KEY';
  final geminiPro =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=API_KEY";

  final header = {'Content-Type': 'application/json'};
  Uint8List? selectedImage;
  final ImagePicker picker = ImagePicker();
  ChatUser currentUser = ChatUser(
    firstName: 'Nabeel',
    id: '1',
  );

  ChatUser otherUser = ChatUser(
    firstName: 'Gemini',
    id: '2',
  );

  List<ChatMessage> allMessages = [];
  List<ChatUser> typing = [];

  getData(ChatMessage message) async {
    typing.add(otherUser);
    allMessages.insert(0, message);
    setState(() {});

    var textData = {
      "contents": [
        {
          "parts": [
            {"text": message.text},
          ]
        }
      ]
    };

    var imageData = {
      "contents": [
        {
          "parts": [
            {"text": message.text},
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data":
                    selectedImage != null ? base64Encode(selectedImage!) : null
              }
            }
          ]
        }
      ]
    };
    String url = selectedImage != null ? geminiProVision : geminiPro;
    var data = selectedImage != null ? imageData : textData;
    await http
        .post(Uri.parse(url), headers: header, body: jsonEncode(data))
        .then((value) {
      if (value.statusCode == 200) {
        var result = jsonDecode(value.body);
        ChatMessage botMessage = ChatMessage(
          user: otherUser,
          createdAt: DateTime.now(),
          text: result['candidates'][0]['content']['parts'][0]['text'],
        );
        allMessages.insert(0, botMessage);
      } else {
        var result = jsonDecode(value.body);
        allMessages.removeLast();
        showErrorDialog(context, 'Error', result['error']['message']);
      }
    }).catchError((e) {
      print(e);
      //Dialog to show error message
      showErrorDialog(
          context, 'Error', 'Something went wrong, Try again later');
    });
    typing.remove(otherUser);
    setState(() {
      selectedImage = null;
    });
  }

  void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void showMessageDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apptreo AI.'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (selectedImage != null)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.memory(
                    selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Expanded(
              child: DashChat(
                inputOptions: InputOptions(
                  leading: [
                    IconButton(
                      icon: Icon(Icons.photo),
                      onPressed: () async {
                        final XFile? photo =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (photo != null) {
                          photo.readAsBytes().then((value) => setState(() {
                                selectedImage = value;
                              }));
                        }
                      },
                    ),
                  ],
                  inputTextStyle: TextStyle(
                    color: Colors.black,
                  ),
                  inputDecoration: InputDecoration(
                    hintText: 'Ask me anything...',
                    hintStyle: TextStyle(
                      color: Colors.black,
                    ),
                    border: InputBorder.none,
                  ),
                ),
                messageOptions: MessageOptions(
                  messagePadding: EdgeInsets.all(10),
                  showTime: true,
                  currentUserContainerColor: Colors.black,
                ),
                typingUsers: typing,
                currentUser: currentUser,
                onSend: (ChatMessage message) {
                  getData(message);
                },
                messages: allMessages,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
