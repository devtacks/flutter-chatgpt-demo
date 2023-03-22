import 'dart:convert';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'kconstant.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  //message will be in the form of [{"question": "", "answer": ""}]
  List<dynamic> messages = [];

  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  _sendMessage() async {
    // initially to show question and show loading in answer text widget.
    messages.add({answer: "", question: _controller.text});
    setState(() {});

    /* 
    post request to get chat response
    - put the api key in Authorization Bearer Header , Store the apiKey in constant file 
    - max_tokens means the maximum character we want to fetch  
        (if we pass max_tokens = 10, we will get a response having text of l0 character long)


    Note: feel free to increase max_token , if you want more detailed text response. for now max_characters is 40.
          max_tokens = (any number) - change in kconstant.dart file
    */

    var response =
        await http.post(Uri.parse("https://api.openai.com/v1/completions"),
            headers: {
              "Accept": "application/json",
              "Content-Type": "application/json",
              "Authorization": "Bearer $apiKey",
            },
            body: jsonEncode({
              "model": "text-davinci-003",
              "prompt": _controller.text,
              "max_tokens": maxTokens,
              "temperature": 0
            }));

    final jsonResp = jsonDecode(response.body);

    /*
      - as the response is stored inside choice , in the first index , we can access the text response
      - messages[messages.length - 1][answer] 
          after reponse, we have access to response
          here we are updating the answer in the last index in answer key of that object. 

    */
    messages[messages.length - 1][answer] = jsonResp["choices"][0]["text"];

    setState(() {});

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: Image.asset(
            "assets/images/ChatGPT-Logo.png",
          ),
          leadingWidth: 80,
          title: const Text("ChatGPT Demo",
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
        ),
        body: SafeArea(
            child: Column(
          children: [
            // lets work on displaying messages
            Flexible(
                child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              height: MediaQuery.of(context).size.height,
              child: messages.isEmpty
                  ? const Text("Search ANything")
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: messages.length,
                      itemBuilder: (context, idx) => _displayMessages(idx)),
            )),
            // show text field
            _buildTextComposer()
          ],
        )));
  }

  // widget to display questions answers - chat messages
  _displayMessages(idx) {
    return Column(
      children: [_displayQuestions(idx), _displayAnswers(idx)],
    );
  }

  // display question - user input

  _displayQuestions(idx) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color.fromARGB(255, 0, 122, 4),
            child: Text(userTitleName),
          ),
          title: Text(
            // replaceFirst is used to remove the new line input string from the start
            messages[idx][question].toString(),
            style: const TextStyle(
              fontSize: 18,
              overflow: TextOverflow.visible,
            ),
          )),
    );
  }

  // display answers - chatbot response
  _displayAnswers(idx) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color.fromARGB(255, 0, 122, 4),
            child: Text(botTitleName),
          ),
          title: messages[idx] != null && messages[idx][answer] == ""
              ? const Text(
                  "Loading...",
                  style: TextStyle(fontSize: 16),
                )
              : AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      // to fix this new line issue we can do use replaceFirst
                      messages[idx][answer].toString().replaceFirst("\n\n", ""),
                      textStyle: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w400,
                          overflow: TextOverflow.visible),
                      speed: const Duration(milliseconds: 300),
                    ),
                  ],
                  totalRepeatCount: 1,
                  pause: const Duration(milliseconds: 100),
                  displayFullTextOnTap: true,
                  stopPauseOnTap: true,
                )),
    );
  }

  // searchbox to search a message
  Widget _buildTextComposer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (value) {
                if (value.isNotEmpty) _sendMessage();
              },
              decoration: const InputDecoration.collapsed(
                  hintText: "Question/description"),
            ),
          ),
          ButtonBar(
            children: [
              IconButton(
                icon: const Icon(Icons.send),
                // if the messages is not empty and last answer is not "" then only
                // we can search a new question
                // if we have input some text, then only we can search the question - text
                onPressed: messages.isNotEmpty && messages.last[answer] == ""
                    ? () {}
                    : () {
                        if (_controller.text.isNotEmpty) _sendMessage();
                        // to hide keyboard
                        SystemChannels.textInput.invokeMethod('TextInput.hide');
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
