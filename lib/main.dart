import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'components/contentPage.dart';
import 'components/loading.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ваше приложение',
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          color: Color.fromARGB(
              255, 235, 178, 13), // Тут указываем нужный цвет фона по умолчанию
        ),
      ),
      home: FutureBuilder<bool>(
        future: _checkCredentials(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Показать загрузочную страницу, пока данные загружаются
            return LoadingPage();
          } else if (snapshot.hasData && snapshot.data!) {
            // Пользователь уже вошел, показать страницу с контентом
            return ContentPage(onLogout: () => _logout(context));
          } else {
            // Пользователь не вошел, показать страницу входа
            return LoginPage();
          }
        },
      ),
    );
  }

  Future<bool> _checkCredentials() async {
    await Future.delayed(Duration(seconds: 2));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionid = prefs.getString('sessionid');
    if (sessionid != null) {
      return true;
    }
    return false;
    // String? username = prefs.getString('username');
    // String? password = prefs.getString('password');
    // return username != null && password != null;
  }
  // сюда закинуть первый фетч и сделать проверку если вообще данные есть
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String erorMessage = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Вход',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              erorMessage,
              style: TextStyle(
                color: Colors.red,
              ),
            ),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Логин',
              ),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Пароль',
              ),
            ),
            SizedBox(height: 46.0),
            Container(
              width: 300.0,
              height: 50.0,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        bool result = await _saveCredentials();
                        result
                            ? Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      ContentPage(
                                          onLogout: () => _logout(context)),
                                ),
                              )
                            : "";
                      },
                style: ElevatedButton.styleFrom(
                  primary:
                      Color.fromARGB(255, 235, 178, 13), // Цвет фона кнопки
                ),
                child: _isLoading
                    ? CircularProgressIndicator(
                        color: Colors.black, // Цвет лоадера
                      )
                    : Text(
                        'Войти',
                        style: TextStyle(fontSize: 20.0, color: Colors.black),
                        // Цвет текста кнопки
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _saveCredentials() async {
    setState(() {
      _isLoading = true;
      erorMessage = "";
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = _usernameController.text;
    String password = _passwordController.text;
    var url = Uri.parse('https://portal.nosu.ru/?login=yes');

    // Создание тела запроса в формате x-www-form-urlencoded
    var requestBody = {
      "AUTH_FORM": 'Y',
      "TYPE": 'AUTH',
      "backurl": "/",
      "USER_LOGIN": username,
      "USER_PASSWORD": password
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
      var responseBody = response.body;
      var setCookieHeader = response.headers['set-cookie'];
      if (setCookieHeader != null) {
        var cookies = setCookieHeader.split(';');
        var cookiesSession = cookies[0].split("=")[1];
        await prefs.setString('sessionid', cookiesSession);
      }
      // ... делайте что-то с данными ответа ...
    } else {
      // Обработка ошибки
      print('Ошибка запроса: ${response.statusCode}');
      setState(() {
        erorMessage = "Неверные данные";
        _isLoading = false;
      });
      return false;
    }
    await prefs.setString('username', username);
    await prefs.setString('password', password);
    setState(() {
      _isLoading = false;
    });
    return true;
    // сюда закинуть еще 1 фетч
  }
}

void _logout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('username');
  await prefs.remove('password');
  await prefs.remove('sessionid');
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (BuildContext context) => LoginPage()),
  );
}
