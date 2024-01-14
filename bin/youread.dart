import 'package:puppeteer/protocol/runtime.dart';
import 'package:puppeteer/puppeteer.dart';
import 'package:youread/youread.dart';

void main() async {
  // Download the Chrome binaries, launch it and connect to the "DevTools"
  var browser = await puppeteer.launch(
    // headless: false,
    executablePath: "/usr/bin/microsoft-edge-stable",
    userDataDir: "./user_data",
    defaultViewport: null,
  );
  // print(browser.wsEndpoint);

  var myPage = await browser.newPage();
  // Go to a page and wait to be fully loaded
  await myPage.goto("https://weread.qq.com/", wait: Until.networkIdle);
  if (!await login(myPage)) {
    throw RuntimeError("登陆失败");
  }

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
  var firstBook =
      await bookShelf.$("a:nth-child(1) > div.wr_bookCover.cover > span");
  await firstBook.click();
  Map<String, ScriptId> jsUrls = {};
  myPage.devTools.network.onRequestWillBeSent.listen((response) {
    if (response.initiator.stack != null) {
      for (var cf in response.initiator.stack!.callFrames) {
        jsUrls[cf.url] = cf.scriptId;
      }
    }
  });
  await myPage.waitForNavigation(wait: Until.networkIdle);
  // https://weread-1258476243.file.myqcloud.com/web/wrwebnjlogic/js/6.21ec78ec.js
  var toolJsUrl =
      await myPage.$("body > script:nth-child(4)").then((element) async {
    return await element
        .property("src")
        .then((url) => url.toString().substring("JsHandle:".length));
  });

  if (!jsUrls.containsKey(toolJsUrl)) {
    throw RuntimeError("之前没有拿到$toolJsUrl的scriptId");
  }

  // 打断点
  var debugger = myPage.devTools.debugger;
  var runtime = myPage.devTools.runtime;
  await debugger.enable();
  debugger.setBreakpointsActive(true);
  await debugger.setBreakpointByUrl(
    0,
    url: toolJsUrl,
    columnNumber: 161610,
    condition: "",
  );
  var jsSrc = debugger
      .getScriptSource(jsUrls[toolJsUrl]!)
      .then((value) => value.scriptSource);

  // 准备注入代码
  // 获取evaluateOnCallFrame的expression参数
  var expression = jsSrc.then((oldCode) {
    var varLen = "_0x15209c".length;
    var anchor = "['bottom']));}for(var ";
    var objNameStartIndex =
        oldCode.indexOf(anchor) + anchor.length + varLen + 1;
    var objNameEndIndex = oldCode.indexOf(",", objNameStartIndex);
    return oldCode.substring(objNameStartIndex, objNameEndIndex);
  });

  debugger.onPaused.listen((event) async {
    print("监听到断点");
    var callFId = event.callFrames[0].callFrameId;
    print("callFrameId: $callFId");
    var arrayObjId = await expression.then((value) => debugger
        .evaluateOnCallFrame(callFId, value)
        .then((response) => response.result.objectId));
    print("Array: $arrayObjId");
    // 获取Array前100个元素
    var functionDeclaration =
        "function(e,t,n){const i=Object.create(null);if(void 0===e||void 0===t||void 0===n)return;if(t-e<n)for(let n=e;n<=t;++n)n in this&&(i[n]=this[n]);else{const n=Object.getOwnPropertyNames(this);for(let o=0;o<n.length;++o){const s=n[o],r=Number(s)>>>0;String(r)===s&&e<=r&&r<=t&&(i[r]=this[r])}}return i}";
    var hundredArrayId = await runtime.callFunctionOn(functionDeclaration,
        objectId: arrayObjId,
        arguments: [
          CallArgument(value: 0),
          CallArgument(value: 99),
          CallArgument(value: 250000)
        ]).then((response) {
      return response.result.objectId;
    });
    print("hundredArrayId: $hundredArrayId");
    var text = await runtime
        .getProperties(hundredArrayId!,
            ownProperties: false,
            accessorPropertiesOnly: false,
            generatePreview: true,
            nonIndexedPropertiesOnly: false)
        .then((response) {
      List<String> tex = [];
      for (var res in response.result) {
        tex.add(res.value!.preview!.properties[4].value!);
      }
      return tex;
    });
    print(text.join());
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
