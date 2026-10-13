# v1.0.1

**版本适配**
- 升级适配 cjc 1.2.0

**新功能**
- 新增 `getInfo(infoType, len)`、`setOption(Int32, Int64)` 方法
- 新增 `OdbcDatasource()` 无参直连构造，用于访问连接池代理无法触达的专有方法

**API 行为变更**
- 参数与列索引从 1 基改为 0 基：`set()`/`setNull()`/`get()`/`getOrNull()` 的 index 从 0 开始，与官方 mysql 驱动行为一致
- `columnInfos` 的 typeName 改为标准命名（如 `SqlInt64`、`SqlString`），旧版 `SqlDbType` 名称仅在 `next(Array<SqlDbType>)` 路径返回
- `setOption()` 由静默无操作改为抛出 `SqlException`
- `SqlException.message` 格式调整为 `<消息>, errorCode: <错误码>`，原始 SqlState 可通过 `odbcState` 属性获取

**兼容性修复**
- 旧版 `SqlDbType` API 恢复可用：`update(Array<SqlDbType>)`、`query(Array<SqlDbType>)`、`next(Array<SqlDbType>)` 不再抛 Deprecated 异常
- 修复 utf8mb4 编码字段（SQL_WVARCHAR/SQL_WCHAR/SQL_WLONGVARCHAR）读取报 "unknown type" 的问题

**Bug 修复**
- `next()` 增加 res==0 判断，防止误读数据
- `readVarColumn` 缓冲按 UTF-8 最坏情况扩容，防止截断

# v1.0.0

1. 升级适配1.0.0
2. 旧接口使用update()需要改成update([])。query()需要改成query([])。

# v0.0.1

1. 基于 odbc 实现 database 包，实现数据库的增删改查
