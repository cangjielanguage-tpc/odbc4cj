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
- 修复 `RealOdbcNativeApi.realloc` 误用 malloc，导致大字段分段读取丢数据、泄漏旧缓冲
- 修复 `next()`/`next(values)` 吞掉 SQL_ERROR 与 SQL_SUCCESS_WITH_INFO，取数失败改为抛出诊断异常
- 修复字符串参数（String/Decimal/BigInt/Gauss Int16）每次执行泄漏一次 mallocCString 缓冲
- 修复 ParamInfo 默认构造即 acquire 空数组句柄导致的内存驻留：默认构造不再 pin 空数组，二进制句柄改为可选（Option）并仅在 setBytes/setClob/setBlob 赋值时 acquire，acquire/release 严格配对
- 修复连接串值包含 '='（如含特殊字符密码）被误判为 "Url is error"
- 修复 UInt8/16/32/64 参数经有符号类型转换静默截断，改用 SQL_C_UTINYINT/USHORT/ULONG/UBIGINT 无符号绑定
- 修复参数描述（SQLDescribeParam）后语句级 5 秒查询超时未恢复，影响后续执行
- 修复 `prepareStatement` 中 sqlPrepare 失败后误用连接句柄取诊断，改为语句句柄以保留真实错误信息
- 修复 getInfoString 固定 256 字节缓冲静默截断长信息，改为按驱动返回的所需长度扩容重取
- 修复结果集包含未映射列类型（如 SQL_GUID/SQL_INTERVAL_*）时整行读取失败，改为该列以 NULL 占位、其余列正常读取
- 修复旧版 next(values) 与新版 next() 的类型分发冲突：新版 fillResultSet 改按原始 ODBC 类型码（rawSqlType）分发，不再依赖可被旧版契约改写的 typeName；旧版调用后 columnInfos 呈现旧版名的契约行为保持不变
- 修复 close() 先置关闭状态再断连导致的错误时序：断连失败改为抛出真实诊断（连接仍存活可重试），并让 sqlDisconnect 原生返回值透传
- `set<T>` 对不支持的 Float16/Rune 类型在设置时立即抛出异常，不再延迟到执行时才报错
- 修复事务隔离级别 getter 误用 SQLGetInfo(SQL_TXN_ISOLATION_OPTION)（驱动"支持"的级别集合而非当前级别，且为位掩码）读取隔离级别，改为 SQLGetConnectAttr(SQL_ATTR_TXN_ISOLATION) 按位匹配，与 setter 写入同一属性，并补全 sqlGetConnectAttr 原生封装
- 修复 readVarColumn 多轮分段读取时向驱动传递总容量而非剩余空间，可能导致驱动越界写
- 修复 readVarColumn 初始缓冲对无限制列（驱动报 0 或超大 displaySize）产生负长度读取或巨量分配，现限制在 [4KB, 16MB] 区间，超出部分由循环扩容兜底
- 修复 GaussDB 下 NULL 参数 BIGINT 绑定不一致：setNull/setNullData 统一改按原始 ODBC 类型码（rawSqlType）分发绑定类型，不再依赖驱动返回的类型名字符串；Gauss BIGINT 统一走 SQL_C_UBIGINT
- 修复 getBytes/getClob/getBlob 逐字节 FFI 拷贝导致的读取性能问题，改为 memcpy 批量拷贝（新增原生 memcpy 封装）
- 修复 setClob/setBlob 逐单字节读流导致的写入性能问题，改为 4096 字节批量读取
- getMetaData 元数据在连接生命周期内不变，首次构建后整表缓存，不再每次调用重复查询 6 次 SQLGetInfo
- 明确标注 OdbcStatement 非线程安全（类注释与 feature_api.md）

# v1.0.0

1. 升级适配1.0.0
2. 旧接口使用update()需要改成update([])。query()需要改成query([])。

# v0.0.1

1. 基于 odbc 实现 database 包，实现数据库的增删改查
