# YouRead
使用puppeteer和devtools协议模拟用户调试行为，自动实现(drawSomeText)处断点，然后获取保存文字的Array Object，逐字读取。

## TODO
以下将包含drawSomeText的javaScript文件称为tool.js(实际是6.21ec78ec.js不知道含义是什么)
### 最高优先级
- [x] 如果用户没有登陆，下载用于登陆的二维码，用户扫码后保存登陆凭据供下次使用
- [x] 获取tool.js的url
- [x] 获取tool.js的scriptId
- [x] 确定tool.js中的函数drawSomeText内部断点位置
- [x] 获取Array Object
- [x] 打印Array中的text
- [ ] 展示用户书架，每本书对应一个ID，用户输入ID打开对应的书，要注意微信读书会重排书架，所以一开始拿到的列表序号不能作为ID
- [ ] 绑定快捷键“下一章”

### 中等优先级
- [ ] 模糊搜索书籍
- [ ] 如果有的书免费不需要登陆，应允许直接打开
- [ ] 如果页面上存在图片，文字中会用\[图片\]替代（这是微信的策略不是我的策略），将对应的图片下载下来


### 最低优先级
- [ ] 包含图片的书籍如何排版？
- [ ] 更进一步，微信读书没有保留任何epub信息，如果要还原为epub如何进行？
