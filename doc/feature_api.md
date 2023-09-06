# odbc4cj库

## 介绍

基于 odbc 实现 database 包。

## odbc

前置条件：NA

场景：

约束：

```
1. 不支持数据类型（SqlTimeTz、SqlTimestamp、SqlInterval），新增支持数据类型请参考 sqlTypeExtend.cj
2. interface Driver 不支持 name、version、preferredPooling
3. Datasource 不支持 setOption(key: String, value: String)，请使用 setOption(key: Int32, value: Int64)
4. interface Connection 不支持 getMetaData()，请使用 getInfo(infoType: UInt16, len: Int16)
5. interface Statement 不支持 setOption(key: String, value: String)，请使用 setOption(key: Int32, value: Int64)
6. interface UpdateResult 不支持 lastInsertId
7. interface Transaction 不支持 accessMode、deferrableMode、save(savePointName: String)、rollback(savepointName: String)、release(savePointName: String)
```

性能：NA

可靠性：NA

### 1  数据库驱动接口

#### 1.1 特性介绍

1. 初始化接口
2. 打开数据源

#### 1.2 实现方案

```
public class OdbcDriver <: Driver {
    /*
    * 初始化接口
    */
    public init()

    /*
    * 通过 connectionString 和选项打开数据源
    *
    * 参数 - connectionString 数据库连接字符串
    * 参数 - opts 打开数据源的选项
    *
    * 返回值 - OdbcDatasource  数据源
    */
    public func open(connectionString: String, opts: Array<(String, String)>): OdbcDatasource
}
```

### 2 数据源接口

#### 2.1 特性介绍

1. 初始化接口
2. 设置连接选项
3. 返回一个可用的连接

#### 2.2  实现方案

```
public class OdbcDatasource <: Datasource {
    /*
    * 初始化接口
    *
    * 参数 - ENV_handle 环境句柄
    * 参数 - dateBase 数据库名
    * 参数 - userName 用户名
    * 参数 - password 密码
    * 参数 - opts 连接选项（只支持 SQL_ATTR_AUTOCOMMIT）
    */
    public init(ENV_handle: CPointer<Unit>, dateBase: String, userName: String, password: String, opts: Array<(String, String)>)

    /*
    * 设置连接选项
    *
    * 参数 - key 属性ID
    * 参数 - value 属性值
    *
    * 返回值 - Unit
    */
    public func setOption(key: Int32, value: Int64): Unit

    /*
    * 返回一个可用的连接
    *
    * 返回值 - OdbcConnection
    */
    public func connect(): OdbcConnection
}
```

### 3 数据库连接接口

#### 3.1 特性介绍

1. 初始化接口
2. 返回有关与连接关联的驱动程序和数据源的常规信息
3. 通过传入的 sql 语句，返回一个预执行的 Statement 对象实例
4. 创建事务对象
5. 关闭连接
6. 判断连接是否关闭

#### 3.2  实现方案

```
public class OdbcConnection <: Connection {
   /*
    * 初始化接口
    *
    * 参数 - DBC_handlePtr 数据源句柄
    * 参数 - dateBase 数据库名
    * 参数 - userName 用户名
    * 参数 - password 密码
    */
    public init(DBC_handlePtr: CPointer<Unit>, dateBase: String, userName: String, password: String)

    /*
    * 返回有关与连接关联的驱动程序和数据源的常规信息，请参考 odbc 接口文档
    *
    * 参数 - infoType 信息类型
    * 参数 - len 信息长度
    *        UInt16: len = 2
    *        UInt32: len = 4
    *        UInt64: len = 8
    *        String: len > 8
    *
    * 返回值 - String
    */
    public func getInfo(infoType: UInt16, len: Int16): String

    /*
    * 通过传入的 sql 语句，返回一个预执行的 Statement 对象实例
    *
    * 参数 - sql sql语句
    *
    * 返回值 - OdbcStatement
    */
    public func prepareStatement(sql: String): OdbcStatement

    /*
    * 创建事务对象（设置手动提交需要调用此方法）
    *
    * 返回值 - OdbcTransaction
    */
    public func createTransaction(): OdbcTransaction

    /*
    * 关闭连接
    *
    * 返回值 - Unit
    */
    public func close(): Unit

    /*
    * 判断连接是否关闭
    *
    * 返回值 - Bool
    */
    public func isClosed(): Bool
}
```

### 4 sql语句预执行接口

#### 4.1 特性介绍

1. 初始化接口
2. 设置预执行 sql 语句选项
3. 执行 sql 语句，得到更新结果
4. 执行 sql 语句，得到查询结果
5. 获取语句句柄

#### 4.2  实现方案

```
public class OdbcStatement <: Statement {
    /*
    * 初始化接口
    *
    * 参数 - DBC_handlePtr 数据源句柄
    */
    public init(DBC_handle: CPointer<Unit>)

    /*
    * 设置预执行 sql 语句选项
    *
    * 参数 - key 属性ID
    * 参数 - value 属性值
    *
    * 返回值 - Unit
    */
    public func setOption(key: Int32, value: Int64): Unit

    /*
    * 执行 sql 语句，得到更新结果
    *
    * 参数 - params SqlDbType数组
    *
    * 返回值 - OdbcUpdateResult
    */
    public func update(params: Array<SqlDbType>): OdbcUpdateResult

    /*
    * 执行 sql 语句，得到查询结果
    *
    * 参数 - params SqlDbType数组
    *
    * 返回值 - QueryResult
    */
    public func query(params: Array<SqlDbType>): QueryResult

    /*
    * 获取语句句柄
    *
    * 返回值 - CPointer<Unit>
    */
    public func getStmtHandle(): CPointer<Unit>
}
```

### 5 执行 Insert、Update、Delete 语句产生的结果接口

#### 5.1 特性介绍

#### 5.2  实现方案

```
public class OdbcUpdateResult <: UpdateResult {
    /*
    * 执行 Insert, Update, Delete 语句影响的行数
    */
    public prop rowCount: Int64
}
```

### 6 执行 Select/Query 语句返回结果的列信息

#### 6.1 特性介绍

#### 6.2  实现方案

```
public class OdbcColumnInfo <: ColumnInfo {
    // 列名或者别名
    public prop name: String

    // 列类型名称，如果在 SqlDataType 中定义，返回 SqlDataType.toString(), 如果未在 SqlDataType 中定义，由数据库驱动定义
    public prop typeName: String

    // 列值的最大显示长度，如果无限制，则应该返回 Int64.Max（仍然受数据库的限制）
    public prop displaySize: Int64

    /**
    * 获取列值大小。
    * 对于数值数据，这是最大精度。
    * 对于字符数据，这是以字符为单位的长度 。
    * 对于日期时间数据类型，这是字符串表示形式的最大字符长度。
    * 对于二进制数据，这是以字节为单位的长度 。
    * 对于 RowID 数据类型，这是以字节为单位的长度 。
    * 对于列大小不适用的数据类型，返回 0。
    */
    public prop length: Int64

    // 列值的小数长度，如果无小数部分，返回 0
    public prop scale: Int64

    // 列值是否允许数据库 Null 值
    public prop nullable: Bool
}
```

### 7 执行 Select 语句产生的结果接口

#### 7.1 特性介绍

1. 初始化接口
2. 获取数据类型
3. 向后移动一行，必须先调用一次 next 才能移动到第一行，第二次调用移动到第二行，依此类推

#### 7.2  实现方案

```
public class OdbcQueryResult <: QueryResult {
    /*
    * 初始化接口
    *
    * 参数 - STMT_handle 语句句柄
    * 参数 - resultCount 列信息
    */
    public init(STMT_handle: CPointer<Unit>, resultCount: Array<OdbcColumnInfo>)

    /*
    * 向后移动一行，必须先调用一次 next 才能移动到第一行，第二次调用移动到第二行，依此类推
    *
    * 参数 - values SqlDbType数组
    *
    * 返回值 - Bool
    */
    public func next(values: Array<SqlDbType>): Bool
}
```

### 8 数据库事务的核心行为

#### 8.1 特性介绍

1. 初始化接口
2. 开始数据库事务
3. 提交数据库事务
4. 从挂起状态回滚事务

#### 8.2  实现方案

```
public class OdbcTransaction <: Transaction {
    /*
    * 初始化接口
    *
    * 参数 - STMT_handle 数据源句柄
    *
    * 返回值 - Unit
    */
    public init(DBC_handlePtr: CPointer<Unit>)

    /*
    * 开始数据库事务
    *
    * 返回值 - Unit
    */
    public func begin(): Unit

    /*
    * 提交数据库事务
    *
    * 返回值 - Unit
    */
    public func commit(): Unit

    /*
    * 从挂起状态回滚事务
    *
    * 返回值 - Unit
    */
    public func commit(): Unit
}
```
