import 'dart:async';
import 'package:puppeteer/puppeteer.dart';
import 'dart:io';
import 'dart:convert';

Future<void> login(Page page) async {
  bool isLogined = false;
  void listenLoginQrCode(Request request) {
    if (!isLogined && request.url.contains("data:image/png")) {
      if (request.url.length > 6000) {
        final imgSrc = request.url.split(",")[1];
        File("login.png").writeAsBytes(base64Decode(imgSrc));
      }
    }
  }

  void listenRereshButton(Response response) {
    if (!isLogined && response.url.contains("login/getinfo")) {
      // 监听刷新按钮的出现
      page.waitForSelector("div.login_dialog_error > button", timeout: Duration.zero).then((retryButton) {
        print("超时，请重新扫码！");
        retryButton!.click();
      });
    }
  }

  // 监听用户的登陆二维码
  page.onRequestFinished.listen(listenLoginQrCode);
  page.onResponse.listen(listenRereshButton);

  // Go to a page and wait to be fully loaded
  await page.goto("https://weread.qq.com/#login", wait: Until.load);

  // 一直等到用户登录
  await page
      .waitForSelector(
    "div.wr_avatar.navBar_avatar > img",
    timeout: Duration.zero,
  )
      .then((_) {
    isLogined = true;
    print("登陆成功！");
  });
}
