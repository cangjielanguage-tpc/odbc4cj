<div align="center">
<h1>odbc4cj</h1>
</div>
<p align="center">
<img alt="" src="https://img.shields.io/badge/release-v0.0.1-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/build-pass-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjc-v0.53.4-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjcov-80.8%25-red" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/project-open-brightgreen" style="display: inline-block;" />
</p>


## 介绍

基于 odbc 实现 database 包。

### 特性

- 🚀 特性1

  数据库驱动接口
- 🚀 特性2

  数据源接口
- 💪 特性3

  数据库连接接口
- 🛠️ 特性4

  sql语句预执行接口
- 🌍 特性5

  执行Insert、Update、Delete语句产生的结果接口
- 💡  特性6

  执行Select/Query语句返回结果的列信息
- 💡  特性7

  执行 Select 语句产生的结果接口
- 💡  特性8

  数据库事务的核心行为

## 软件架构

### 源码目录

```shell
.
├─ doc
├─ README.md
├─ README.OpenSource
├─ src
└─ test
   ├─ HLT
   └─ LLT
```

- `doc`  文档目录，用于存放设计、API接口等文档
- `src`  源码目录
- `test` 测试目录

### 接口说明

主要类和函数接口说明详见 [API](./doc/feature_api.md)

## 使用说明

### 编译构建

1、安装

linux安装 unixODBC

https://learn.microsoft.com/zh-cn/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver16&tabs=alpine18-install%2Calpine17-install%2Cdebian8-install%2Credhat7-13-install%2Crhel7-offline

window安装

https://learn.microsoft.com/zh-cn/sql/connect/odbc/windows/microsoft-odbc-driver-for-sql-server-on-windows?view=sql-server-ver16

2、克隆项目

```shell
git clone https://gitcode.com/Cangjie-TPC/odbc4cj.git
```

3、切换目录

```shell
cd odbc4cj
```

4、在当前目录新建 lib 文件夹

5、迁移lib

linux 环境下 将 libodbc.so复制到lib中。libodbc.so通常在 /usr/lib/x86_64-linux-gnu/ 目录下

window 环境下 将 libmyodbc8a.dll、libcrypto-1_1-x64.dll、libsasl.dll、libssl-1_1-x64.dll复制到lib中。将 cjpm.toml文件中的 odbc = {path = "./lib/"} 改成 myodbc8a = {path = "./lib/"}。libmyodbc8a.dll 下载mysql版本的odbc插件目录中，libcrypto-1_1-x64.dll、libsasl.dll、libssl-1_1-x64.dll在window系统目录中

6、编译项目

```shell
cjpm build
```

7、编译示例文件

示例文件在 /test/DOC/test_example1.cj  
${path}修改成用户自己项目本地路径

linux 编译指令

```shell
cp ${path}/libs/libodbc.so ${path}/odbc4cj/target/release/odbc4cj   ---> 复制so到指定路径

cd target/release/odbc4cj   ---> 切换目录

cjc  --import-path ${path}/odbc4cj/target/release -L ${path}/odbc4cj/target/release/odbc4cj -l odbc -l odbc4cj ${path}/odbc4cj/test/DOC/test_example1.cj -O0 -Woff alll  ---> 编译 test/LLT 用例

```

windows 编译指令

```cmd
cp ${path}/libs/libmyodbc8a.dll ${path}/odbc4cj/target/release/odbc4cj   ---> 复制dll到指定路径
cp ${path}/libs/libcrypto-1_1-x64.dll ${path}/odbc4cj/target/release/odbc4cj   ---> 复制dll到指定路径
cp ${path}/libs/libsasl.dll ${path}/odbc4cj/target/release/odbc4cj   ---> 复制dll到指定路径
cp ${path}/libs/libssl-1_1-x64.dll ${path}/odbc4cj/target/release/odbc4cj   ---> 复制dll到指定路径

cd target/release/odbc4cj   ---> 切换目录

cjc  --import-path ${path}/odbc4cj/target/release -L ${path}/odbc4cj/target/release/odbc4cj -l crypto-1_1-x64 -l myodbc8a -l sasl -l ssl-1_1-x64 -l odbc4cj ${path}/odbc4cj/test/DOC/test_example1.cj -O0 -Woff alll  ---> 编译 test/LLT 用例
```

8、运行执行文件

linux 运行

```shell
./main
```

windows 运行

```cmd
./main.exe
```

### 功能示例

```cangjie
import std.database.sql.* 
import std.io.*
import std.time.*
import std.regex.*
import odbc4cj.*

main() {
    var driver = OdbcDriver()
    var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
    var conn = database.connect()
    var prepareStatement = conn.prepareStatement("drop table if exists test")
    var rowCount = prepareStatement.update()
    prepareStatement = conn.prepareStatement("create table test(data int NOT NULL, datanull int)")
    rowCount = prepareStatement.update()
    prepareStatement = conn.prepareStatement("insert into test values(?,?)")
    rowCount = prepareStatement.update([SqlInteger(12345), SqlNullableInteger(None)])
    prepareStatement = conn.prepareStatement("select * from test")
    var queryResult = prepareStatement.query()
    var arr: Array<SqlDbType> = [SqlInteger(1), SqlNullableInteger(1)]
    queryResult.next(arr)
    match (arr[0]) {
        case v: SqlInteger => println(v.value)
        case _ => ()
    }
    match (arr[1]) {
        case v: SqlNullableInteger => println(v.value)
        case _ => ()
    }
}
```

执行结果如下：

```
12345
None
```

## 约束与限制

1. 不支持数据类型（SqlTimeTz、SqlTimestamp、SqlInterval），新增支持数据类型请参考 sqlTypeExtend.cj
2. interface Driver 不支持 name、version、preferredPooling
3. Datasource 不支持 setOption(key: String, value: String)，请使用 setOption(key: Int32, value: Int64)
4. interface Connection 不支持 getMetaData()，请使用 getInfo(infoType: UInt16, len: Int16)
5. interface Statement 不支持 setOption(key: String, value: String)，请使用 setOption(key: Int32, value: Int64)
6. interface UpdateResult 不支持 lastInsertId
7. interface Transaction 不支持 accessMode、deferrableMode、save(savePointName: String)、rollback(savepointName: String)、release(savePointName: String)

## 开源协议

本项目基于 [木兰宽松许可证](./LICENSE)，请自由的享受和参与开源。

## 参与贡献

欢迎给我们提交PR，欢迎给我们提交Issue，欢迎参与任何形式的贡献。
