# YouRead
使用puppeteer和devtools协议模拟用户调试行为，自动实现(drawSomeText)处断点，然后获取保存文字的Array Object，逐字读取。

### TODO
以下将包含drawSomeText的javaScript文件称为tool.js(实际是6.21ec78ec.js不知道含义是什么)
- [x] 如果用户没有登陆，下载用于登陆的二维码，用户扫码后保存登陆凭据供下次使用
- [x] 获取tool.js的url
- [x] 获取tool.js的scriptId
- [x] 确定tool.js中的函数drawSomeText内部断点位置
- [x] 获取Array Object
