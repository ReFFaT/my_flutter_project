import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'dart:convert';

class ContentPage extends StatefulWidget {
  final VoidCallback onLogout;

  const ContentPage({Key? key, required this.onLogout}) : super(key: key);

  @override
  _ContentPageState createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  String _username = '';
  String _password = '';
  String _sessionid = '';
  String _userImage = '';
  String _nameText = "";
  bool _showQrCode = true;
  bool loading = false;
  String QrText = 'Qr Code';
  @override
  void initState() {
    super.initState();
    _loadCredentials();
    _generateQrCode();
  }

  void _loadCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    String? password = prefs.getString('password');
    String? sessionid = prefs.getString('sessionid');
    if (password == '') {
      password = 'Нет данных';
    }
    if (username == '') {
      username = 'Нет данных';
    }
    if (sessionid != null && sessionid == '') {
      sessionid = 'Нет данных';
    }
    setState(() {
      _username = username ?? 'Не существует username';
      _password = password ?? 'Не существует password';
      _sessionid = sessionid ?? 'Не существует sessionid';
    });

    var url =
        Uri.parse('https://portal.nosu.ru/bitrix/vuz/api/profile/current');

    // Создание тела запроса в формате x-www-form-urlencoded

    var response = await http.get(
      url,
      headers: {
        'Cookie': 'PHPSESSID=$_sessionid; PORTAL_NOSU_BX_PROFILE_ID=15756',
      },
    );
    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      print(jsonResponse["user"]["fullname"]);
      setState(() {
        if (jsonResponse["user"]["photo"]["thumbnail"] != null) {
          _userImage = "https://portal.nosu.ru" +
              jsonResponse["user"]["photo"]["thumbnail"];
        } else {
          _userImage = "https://cdn-icons-png.flaticon.com/512/149/149452.png";
        }
        _nameText = jsonResponse["user"]["fullname"];
      });
    } else {
      // Обработка ошибки

      print('Ошибка запроса: ${response.statusCode}');
    }
    // Проверка статуса ответа и обработка данных
    print(_sessionid);
    print(response.statusCode);
  }

  void _generateQrCode() async {
    setState(() {
      loading = true;
    });
    if (_username.isNotEmpty && _password.isNotEmpty) {
      setState(() {
        _showQrCode = true;
      });
      await _generateQrData();
    }
    setState(() {
      loading = false;
    });
  }

  Future<void> _generateQrData() async {
    var url = Uri.parse('https://portal.nosu.ru/?login=yes');

    // Создание тела запроса в формате x-www-form-urlencoded
    var requestBody = {
      "AUTH_FORM": 'Y',
      "TYPE": 'AUTH',
      "backurl": "/",
      "USER_LOGIN": _username,
      "USER_PASSWORD": _password
    };
    var body = Uri(queryParameters: requestBody).query;

    var response = await http.post(
      url,
      headers: {
        'Content-Type':
            MediaType.parse('application/x-www-form-urlencoded').toString(),
      },
      body: body,
    );

    // Проверка статуса ответа и обработка данных
    if (response.statusCode == 302) {
      var setCookieHeader = response.headers['set-cookie'];
      if (setCookieHeader != null) {
        var cookies = setCookieHeader.split(';');
        _sessionid = cookies[0].split("=")[1];
      }
      // ... делайте что-то с данными ответа ...
    } else {
      // Обработка ошибки
      setState(() {
        _showQrCode = false;
        QrText = "Ошибка данных, пожалуйста авторизуйтесь по новой";
      });

      print('Ошибка запроса: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Согу',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: widget.onLogout,
            color: Colors.black,
            icon: Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(_userImage),
                    radius: 50,
                  ),
                  SizedBox(height: 10),
                  Text(
                    _nameText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 26.0),
            _showQrCode
                ? QrImage(
                    data: '$_sessionid',
                    version: QrVersions.auto,
                    size: 300.0,
                  )
                : Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Center(
                      child: Text(
                        QrText,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                  ),
            SizedBox(height: 86.0),
            Container(
              width: 300.0, // Ширина кнопки 300 пикселей
              height: 50.0,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary:
                      Color.fromARGB(255, 235, 178, 13), // Цвет фона кнопки
                ),
                onPressed: loading ? null : _generateQrCode,
                child: loading
                    ? CircularProgressIndicator(
                        color: Colors.black, // Цвет лоадера
                      )
                    : Text(
                        'Запросить QR-Code',
                        style: TextStyle(
                            fontSize: 20.0,
                            color: Colors.black), // Цвет текста кнопки
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
