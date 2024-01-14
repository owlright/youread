import 'dart:async';
import 'package:puppeteer/puppeteer.dart';
import 'dart:io';
import 'dart:convert';

Future<bool> login(Page page) async {
  await page
      .evaluate<String>('() => document.title')
      .then((value) => print(value));

  try {
    await page.waitForSelector(
      "div.wr_avatar.navBar_avatar > img",
      timeout: const Duration(seconds: 1),
    );
    print("你已经登陆");
    return true;
  } catch (e) {
    if (e is TimeoutException) {
      print("请扫码");
    }
  }

  page
      .waitForSelector("button.navBar_link.navBar_link_Login")
      .then((loginButton) => loginButton?.click());

  page
      .waitForSelector(
    "div.login_dialog_qrcode > img",
    timeout: const Duration(seconds: 1),
  )
      .then((imgElem) {
    imgElem?.property("src").then((imgSource) {
      String img = imgSource.toString().split(",")[1];
      var bytes = base64Decode(img);
      File("login.png").writeAsBytes(bytes);
    });
  });

  page
      .waitForSelector(
          "#app > div.navBar_home > div.navBar > div > div > div > div")
      .then((value) {
    print("登陆成功");
  });
  return true;
}