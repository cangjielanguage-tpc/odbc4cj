<div align="center">
<h1>库名</h1>
</div>
<p align="center">
<img alt="" src="https://img.shields.io/badge/release-v0.0.1-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/build-pass-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjc-v0.39.4-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjcov-50%25-red" style="display: inline-block;" />
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

  执行Select/Query语句返回结果的列信息

- 💡  特性6

  执行 Select 语句产生的结果接口

- 💡  特性7

  数据库事务的核心行为

### 路线

<p align="center">
<img src="./doc/assets/milestone.png" width="100%" >
</p>
路线图roadmap在 doc/framework-roadmap-logo.pptx 中有源文件。


## 软件架构

### 架构图

<p align="center">
<img src="./doc/assets/framework.png" width="60%" >
</p>

架构图文字说明，包括模块说明、架构层次等详细说明。

### 源码目录

```shell
.
├─ doc
├─ README.md
├─ README.OpenSource
├─ src
│  ├─ columnInfo.cj
│  ├─ connection.cj
│  ├─ datasource.cj
│  ├─ driver.cj
│  ├─ native.cj
│  ├─ queryResult.cj
│  ├─ statement.cj
│  ├─ transaction.cj
│  ├─ updateResult.cj
│  └─ util.cj
└─ test
   ├─ HLT
   └─ LLT
```

- `doc`  文档目录，用于存放设计、API接口等文档
- `src`  源码目录
- `test` 测试目录

### 接口说明

主要类和函数接口说明详见 [API](./doc/api.md)


## 使用说明

### 编译构建

描述具体的编译过程：

```shell
cjpm build
```

### 功能示例
```cangjie
package odbc
from std import database.sql.*, io.*, time.*, regex.*
from odbc4cj import odbc.*

main() {
    var driver = OdbcDriver()
    var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
    var conn = database.connect()
    var prepareStatement = conn.prepareStatement("drop table if exists test")
    var rowCount = prepareStatement.update()
    prepareStatement = conn.prepareStatement("create table test(data int NOT NULL, datanull int)")
    rowCount = prepareStatement.update()
    prepareStatement = conn.prepareStatement("insert into test values(?,?)")
    rowCount = prepareStatement.update([SqlIntger(12345), SqlNullableIntger(None)])
    prepareStatement = conn.prepareStatement("select * from test")
    var queryResult = prepareStatement.query()
    var arr: Array<SqlDbType> = queryResult.getSqlDbType()
    queryResult.next(arr)
    match (arr[0]) {
        case v: SqlIntger => println(v.value)
        case _ => ()
    }
    match (arr[1]) {
        case v: SqlNullableIntger => println(v.value)
        case _ => ()
    }
}


```

执行结果如下：

```shell
12345
None
```

## 开源协议
MulanPSL-2.0 License

## 参与贡献

欢迎给我们提交PR，欢迎给我们提交Issue，欢迎参与任何形式的贡献。