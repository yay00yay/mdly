//ref : https://blog.csdn.net/zl_china/article/details/129756110

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(GetMaterialApp(
    home: ChatPage(),
  ));
  //runApp(const MyApp());
}

class ApiProvider extends GetConnect {
  final String apiKey = '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';
  final String baseUrl = 'https://api.openai.com';
  final Duration timeout = Duration(seconds: 30);

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bear $apiKey',
    };
  }

  ApiProvider() {
    httpClient.baseUrl = baseUrl;
    httpClient.timeout = timeout;
    httpClient.addRequestModifier<void>((request) {
      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] =
          'Bearer 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';
      return request;
    });
  }

  Future<Response> completions(String body) {
    return post('/v1/completions', body);
  }
}

class ChatLogic extends GetxController {
  final ChatState state = ChatState();
  final ApiProvider provider = ApiProvider();

  Future<void> sendMessage(String content) async {
    state.requestStatus(content);
    update();
    final response = await provider.completions(json.encode({
      "model": "text-davinci-003",
      "prompt": content,
      "temperature": 0.7,
      "max_tokens": 2260,
      "top_p": 1,
      "frequency_penalty": 0,
      "presence_penalty": 0
    }));
    try {
      if (response.statusCode == 200) {
        final data = response.body;
        final text = data['choices'][0]['text'];
        state.responseStatus(text);
      } else {
        state.responseStatus(response.statusText ?? '请求错误，请稍后重试');
      }
    } catch (error) {
      state.responseStatus(error.toString());
    }
    update();
  }
}

class ChatState {
  String message = '';
  String sender = 'user';
  bool isRequesting = false;
  List<Map<String, dynamic>> messages = [];

  void requestStatus(String content) {
    messages.add({'text': content, 'sender': 'user'});
    sender = 'bot';
    messages.add({'text': '正在回复中...', 'sender': sender});
    isRequesting = true;
    message = '';
  }

  void responseStatus(String content) {
    messages.removeLast(); // Remove "正在回复中..." 状态
    messages.add({'text': content, 'sender': sender});
    sender = 'user';
    isRequesting = false;
  }
}

class ChatPage extends StatelessWidget {
  ChatPage({Key? key}) : super(key: key);

  final logic = Get.put(ChatLogic());
  final state = Get.find<ChatLogic>().state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('你问我答'),
      ),
      body: GetBuilder<ChatLogic>(
        builder: (context) => Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: state.messages.length,
                itemBuilder: (BuildContext context, index) {
                  Map m = state.messages[index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: m['sender'] == 'user'
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                color: m['sender'] == 'user'
                                    ? Colors.green[100]
                                    : Colors.white),
                            child: Text(m['text']),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.0),
                    topRight: Radius.circular(12.0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                          decoration: const InputDecoration(
                            hintText: '请输入消息',
                            border: InputBorder.none,
                          ),
                          controller:
                              TextEditingController(text: state.message),
                          onChanged: (value) {
                            state.message = value;
                          }),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: state.isRequesting
                        ? null
                        : () {
                            logic.sendMessage(state.message);
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
