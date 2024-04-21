import 'dart:io';

import 'package:puppeteer/protocol/runtime.dart';
import 'package:puppeteer/puppeteer.dart';
// import 'package:args/args.dart';
import 'package:youread/youread.dart';

void main(List<String> arguments) async {
  // TODO: 通过命令行参数指定浏览器路径
  // TODO: 用户提供edge/chrome后，自动补充路径，实在不行才要求用户手动输入
  // final parser = ArgParser()
  //   ..addFlag("executablePath", negatable: false, abbr: 'e');
  // ArgResults argResults = parser.parse(arguments);
  // if (argResults["executablePath"] as bool) {
  //   print("executablePath: ${argResults.rest[0]}");
  //   return;
  // }
  var chromePath = "";
  if (Platform.isWindows) {
    chromePath = "C://Program Files//Google//Chrome//Application//chrome.exe"; //
  } else if (Platform.isLinux) {
    chromePath = "/usr/bin/microsoft-edge-stable";
  } else if (Platform.isMacOS) {
    chromePath = "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge";
  } else {
    throw UnsupportedError("Unsupported platform");
  }
  // Download the Chrome binaries, launch it and connect to the "DevTools"
  var browser = await puppeteer.launch(
    // headless: false,
    executablePath: chromePath,
    userDataDir: "./user_data",
    defaultViewport: null,
  );
  // print(browser.wsEndpoint);

  var myPage = await browser.newPage();
  await login(myPage);

  await myPage.goto("https://weread.qq.com/web/shelf", wait: Until.networkIdle);
  var bookShelf = await myPage.$("#routerView > div.shelf_list");
  // var numBooks = await myPage.evaluate<int>(
  //     'el => el.getElementsByTagName("a").length',
  //     args: [shelf]);
  // for (var i = 0; i < numBooks; i++) {
  //   shelf.$("a:nth-child(${i + 1}) > div.title").then((bookHandle) {
  //     bookHandle.property("textContent").then((value) {
  //       print("$i ${value.remoteObject.value}");
  //     });
  //   });
  // }
  var firstBook = await bookShelf.$("a:nth-child(1) > div.wr_bookCover.cover > span");
  await firstBook.click();
  Map<String, ScriptId> jsUrls = {};
  myPage.devTools.network.onRequestWillBeSent.listen((response) {
    if (response.initiator.stack != null) {
      for (var cf in response.initiator.stack!.callFrames) {
        jsUrls[cf.url] = cf.scriptId;
      }
    }
    // print(jsUrls);
  });
  await myPage.waitForNavigation(wait: Until.networkIdle);
  // 类似这样：https://weread-1258476243.file.myqcloud.com/web/wrwebnjlogic/js/6.21ec78ec.js
  var toolJsUrl = await myPage.$("body > script:nth-child(4)").then((element) async {
    var toolJs = await element.property("src").then((url) => url.toString().substring("JsHandle:".length));
    // print(toolJs);
    return toolJs;
  });

  if (!jsUrls.containsKey(toolJsUrl)) {
    throw RuntimeError("之前没有拿到$toolJsUrl的scriptId");
  }

  // 打断点
  var debugger = myPage.devTools.debugger;
  await debugger.enable();
  debugger.setBreakpointsActive(true);
  await debugger.setBreakpointByUrl(
    0,
    url: toolJsUrl,
    columnNumber: 67151, // figure out the column number by yourself
    condition: "",
  );
  var jsSrc = debugger.getScriptSource(jsUrls[toolJsUrl]!).then((value) => value.scriptSource);

  debugger.onPaused.listen((event) async {
    print("监听到断点");
    var callFId = event.callFrames[0].callFrameId;
    print("callFrameId: $callFId");
    var [cssObjStr, htmlObjStr] = await jsSrc.then((oldCode) {
      final cssObjRegExp = RegExp(r" (\w+)=(\w+)\['dS'\]");
      final htmlObjRegExp = RegExp(r";(\w+)=(\w+)\['dH'\]");

      final cssMatch = cssObjRegExp.firstMatch(oldCode)!;
      final htmlMatch = htmlObjRegExp.firstMatch(oldCode)!;
      return [cssMatch.group(1)!, htmlMatch.group(1)!];
    });
    await debugger.evaluateOnCallFrame(callFId, cssObjStr).then((response) {
      print("css: ${response.result.type} ${response.result.value}");
    });
    await debugger.evaluateOnCallFrame(callFId, htmlObjStr).then((response) {
      print("html: ${response.result.type} ${response.result.value}");
    });

    await debugger.setBreakpointsActive(false);
    await debugger.resume();
    // Gracefully close the browser's process
    await browser.close();
  });

  // 点击下一章按钮
  await myPage
      .$("#routerView > div.app_content > div.readerFooter > div > button")
      .then((button) async => await button.click());
}
