<div align="center">
<h1>odbc4cj</h1>
</div>
<p align="center">
<img alt="" src="https://img.shields.io/badge/release-v0.0.1-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/build-pass-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjc-v0.39.8-brightgreen" style="display: inline-block;" />
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

### 约束

```
1. 不支持数据类型（SqlTimeTz、SqlTimestamp、SqlInterval），新增支持数据类型请参考 sqlTypeExtend.cj
2. interface Driver 不支持 name、version、preferredPooling
3. Datasource 不支持 setOption(key: String, value: String)，请使用 setOption(key: Int32, value: Int64)
4. interface Connection 不支持 getMetaData()，请使用 getInfo(infoType: UInt16, len: Int16)
5. interface Statement 不支持 setOption(key: String, value: String)，请使用 setOption(key: Int32, value: Int64)
6. interface UpdateResult 不支持 lastInsertId
7. interface Transaction 不支持 accessMode、deferrableMode、save(savePointName: String)、rollback(savepointName: String)、release(savePointName: String)
```

## 软件架构

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
│  ├─ sqlTypeExtend.cj
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

主要类和函数接口说明详见 [API](./doc/feature_api.md)

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

编译执行：

```
cjc --import-path build  -Lbuild/odbc4cj -l myodbc8a -l odbc4cj_odbc  testExample1.cj -o main
```

执行结果如下：

```
12345
None
```

## 开源协议

MulanPSL-2.0 License

## 参与贡献

欢迎给我们提交PR，欢迎给我们提交Issue，欢迎参与任何形式的贡献。
