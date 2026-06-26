package odbc4cj

import std.io.*

public class OdbcStatement <: Statement {
    private let nativeApi: OdbcNativeApi
    private var STMT_handlePtr: CPointer<Unit>
    private let closed = AtomicBool(false)
    var odbcConnection: OdbcConnection
    private var params: ?Array<Any> = None
    private var cachedParamInfos: ?Array<ColumnInfo> = None
    private var paramInfoFetchFailed: Bool = false

    /*
     * 预执行sql语句中，占位参数的列信息，比如列名，列类型，列长度，是否允许数据库Null值等
     */
    public override prop parameterColumnInfos: Array<ColumnInfo> {
        get() {
            if (let Some(cached) <- cachedParamInfos) {
                return cached
            }
            var result = computeParameterColumnInfos()
            cachedParamInfos = result
            return result
        }
    }
    private func computeParameterColumnInfos(): Array<ColumnInfo> {
        var ParameterCountPtr = nativeApi.malloc(LEN_MALLOC_2)
        if (ParameterCountPtr.isNull()) {
            throw SqlException("Native malloc Failed.")
        }
        unsafe {
            CPointer<Int16>(ParameterCountPtr).write(0)
            var ret = nativeApi.sqlNumParams(STMT_handlePtr, CPointer<Int16>(ParameterCountPtr))
            if (!SQLSucceeded(ret)) {
                var exception = nativeApi.diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
                nativeApi.free(ParameterCountPtr)
                throw exception
            }
            var len = CPointer<Int16>(ParameterCountPtr).read()
            nativeApi.free(ParameterCountPtr)
            if (len != 0) {
                var arrInfo: Array<ColumnInfo> = Array<ColumnInfo>(Int64(len), repeat: OdbcColumnInfo())
                //设置5秒超时，避免永久阻塞
                let timeoutValue: Int64 = 5
                nativeApi.sqlSetStmtAttr(this.STMT_handlePtr, SQL_ATTR_QUERY_TIMEOUT, timeoutValue, SQL_IS_INTEGER)
                var hadToUseFallback = false
                for (i in 0..len) {
                    var dataTypePtr = nativeApi.malloc(LEN_MALLOC_2)
                    var parameterSizePtr = nativeApi.malloc(LEN_MALLOC_8)
                    var decimalDigitsPtr = nativeApi.malloc(LEN_MALLOC_2)
                    var nullablePtr = nativeApi.malloc(LEN_MALLOC_2)
                    if (dataTypePtr.isNull() || parameterSizePtr.isNull() || decimalDigitsPtr.isNull() ||
                        nullablePtr.isNull()) {
                        if (!dataTypePtr.isNull()) {
                            nativeApi.free(dataTypePtr)
                        }
                        if (!parameterSizePtr.isNull()) {
                            nativeApi.free(parameterSizePtr)
                        }
                        if (!decimalDigitsPtr.isNull()) {
                            nativeApi.free(decimalDigitsPtr)
                        }
                        if (!nullablePtr.isNull()) {
                            nativeApi.free(nullablePtr)
                        }
                        arrInfo[Int64(i)] = OdbcColumnInfo("", "SqlString", 4000, 0, 0, SQL_NULLABLE_UNKNOWN)
                        hadToUseFallback = true
                    } else {
                        ret = nativeApi.sqlDescribeParam(this.STMT_handlePtr, UInt16(i + 1),
                            CPointer<Int16>(dataTypePtr), CPointer<UInt64>(parameterSizePtr),
                            CPointer<Int16>(decimalDigitsPtr), CPointer<Int16>(nullablePtr))
                        if (SQLSucceeded(ret)) {
                            let typeName = getSqlTypeName(CPointer<Int16>(dataTypePtr).read())
                            let colSize = CPointer<UInt64>(parameterSizePtr).read()
                            let decimalDigits = CPointer<Int16>(decimalDigitsPtr).read()
                            let nullable = CPointer<Int16>(nullablePtr).read()
                            arrInfo[Int64(i)] = OdbcColumnInfo("", typeName, Int64(colSize), decimalDigits, 0, nullable)
                        } else {
                            println(
                                "[ODBC Statement] sqlDescribeParam failed for param ${i + 1}, using default SqlString type")
                            arrInfo[Int64(i)] = OdbcColumnInfo("", "SqlString", 4000, 0, 0, SQL_NULLABLE_UNKNOWN)
                            hadToUseFallback = true
                        }
                        nativeApi.free(dataTypePtr)
                        nativeApi.free(parameterSizePtr)
                        nativeApi.free(decimalDigitsPtr)
                        nativeApi.free(nullablePtr)
                    }
                }
                if (hadToUseFallback) {
                    paramInfoFetchFailed = true
                }
                return arrInfo
            } else {
                return Array<ColumnInfo>()
            }
        }
    }

    init(nativeApi: OdbcNativeApi, STMT_handlePtr: CPointer<Unit>, odbcConnection: OdbcConnection) {
        this.nativeApi = nativeApi
        if (odbcConnection.isClosed()) {
            throw SqlException("The database connection has been closed")
        }
        this.STMT_handlePtr = STMT_handlePtr
        this.odbcConnection = odbcConnection
    }

    /**
     * 设置预执行 sql 语句选项
     */
    public override func setOption(key: String, value: String): Unit {
    }

    /**
     * 设置预执行sql语句参数
     *
     * 参数 index - 位置
     * 参数 value - 值
     * 异常 Exception - 参数设置错误。
     */
    public override func set<T>(index: Int, value: T): Unit {
        checkResource()
        if (index < 1) {
            throw IllegalArgumentException("The parameter index must be greater than 0")
        }
        if (this.params.isNone()) {
            let parameterColumnInfosNew: Array<ColumnInfo> = parameterColumnInfos
            if (index > parameterColumnInfosNew.size) {
                throw SqlException(
                    "parameter index error, index {:${index}},ColumnInfo size {${parameterColumnInfosNew.size}}")
            }
            this.params = Array<Any>(parameterColumnInfosNew.size, repeat: Option<Any>.None)
        }

        if (index > this.params.getOrThrow().size) {
            throw SqlException(
                "parameter index error, index {:${index}}, ColumnInfo size {${this.params.getOrThrow().size}}")
        }
        func unwrap<T>(value: ?T) {
            if (let Some(v) <- value) {
                params.getOrThrow()[index - 1] = v
            } else {
                setNull(index)
            }
        }
        match (value) {
            case v: ?Bool => unwrap(v)
            case v: ?Int8 => unwrap(v)
            case v: ?UInt8 => unwrap(v)
            case v: ?Int16 => unwrap(v)
            case v: ?UInt16 => unwrap(v)
            case v: ?Int32 => unwrap(v)
            case v: ?UInt32 => unwrap(v)
            case v: ?Int64 => unwrap(v)
            case v: ?UInt64 => unwrap(v)
            case v: ?Float16 => unwrap(v)
            case v: ?Float32 => unwrap(v)
            case v: ?Float64 => unwrap(v)
            case v: ?Rune => unwrap(v)
            case v: ?String => unwrap(v)
            case v: ?DateTime => unwrap(v)
            case v: ?BigInt => unwrap(v)
            case v: ?Decimal => unwrap(v)
            case v: ?Array<Byte> => unwrap(v)
            case v: ?InputStream => unwrap(v)
            case _ => params.getOrThrow()[index - 1] = value
        }
    }

    /**
     * 设置预执行sql语句null参数
     *
     * 参数 index - 位置
     * 异常 Exception - 参数设置错误。
     */
    public override func setNull(index: Int): Unit {
        checkResource()
        if (index < 1) {
            throw IllegalArgumentException("The parameter index must be greater than 0")
        }
        if (this.params.isNone()) {
            let parameterColumnInfosNew: Array<ColumnInfo> = parameterColumnInfos
            if (index > parameterColumnInfosNew.size) {
                throw SqlException("parameter index error")
            }
            this.params = Array<Any>(parameterColumnInfosNew.size, repeat: Option<Any>.None)
        }
        if (index > params.getOrThrow().size) {
            throw SqlException("parameter index error")
        }
        let colInfo = parameterColumnInfos[index - 1]
        var paramInfo = ParamInfo()
        var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (strLenOrInd.isNull()) {
            throw SqlException("Native malloc failed")
        }
        unsafe { strLenOrInd.write(SQL_NULL_DATA) }
        paramInfo.strLenOrInd = strLenOrInd

        let (vt, pt) = match (colInfo.typeName) {
            case "TINYINT" | "SqlInt8" => (SQL_C_STINYINT, SQL_TINYINT)
            case "SMALLINT" | "SqlInt16" => (SQL_C_SSHORT, SQL_SMALLINT)
            case "INTEGER" | "SqlInt32" => (SQL_C_SLONG, SQL_INTEGER)
            case "BIGINT" | "SqlInt64" => (SQL_C_SBIGINT, SQL_BIGINT)
            case "REAL" | "FLOAT" | "SqlFloat" => (SQL_C_FLOAT, SQL_FLOAT)
            case "DOUBLE" | "SqlDouble" => (SQL_C_DOUBLE, SQL_DOUBLE)
            case "VARCHAR" | "CHAR" | "CLOB" | "DECIMAL" | "SqlString" | "SqlNumeric" => (SQL_C_CHAR, SQL_VARCHAR)
            case "VARBINARY" | "BINARY" | "BLOB" | "SqlBytes" => (SQL_C_BINARY, SQL_VARBINARY)
            case "DATE" | "SqlDate" => (SQL_C_TYPE_DATE, SQL_TYPE_DATE)
            case "TIME" | "SqlTime" => (SQL_C_TYPE_TIME, SQL_TYPE_TIME)
            case "TIMESTAMP" | "SqlTimestamp" => (SQL_C_TYPE_TIMESTAMP, SQL_TYPE_TIMESTAMP)
            case _ => (SQL_C_CHAR, SQL_VARCHAR)
        }
        paramInfo.valueType = vt
        paramInfo.parameterType = pt
        params.getOrThrow()[index - 1] = paramInfo
    }

    /**
     * 执行sql语句，得到更新结果
     *
     * 返回值 UpdateResult - 更新结果。
     * 异常 Exception - 传入参数错误。
     */
    public override func update(): UpdateResult {
        checkResource()
        let parameterColumnInfosNew: Array<ColumnInfo> = parameterColumnInfos
        var ret: Int16

        if (this.params.isNone() && parameterColumnInfosNew.size > 0) {
            this.params = Array<Any>(parameterColumnInfosNew.size, repeat: Option<Any>.None)
        }
        var paramInfo: Array<ParamInfo> = match (params) {
            case Some(v) => getParamInfo(v)
            case None => Array<ParamInfo>()
        }
        //打印所有绑定的详细数据
        for (i in 0..paramInfo.size) {
            let p = paramInfo[i]
            println(
                "param[${i + 1}]: valueType = ${sqlTypeToString(p.valueType)}, parameterType = ${sqlTypeToString(p.parameterType)},   columnSize = ${p.columnSize}, decimalDigits = ${p.decimalDigits}, bufferLength = ${p.bufferLength},isString = ${p.isString}, isArray = ${p.isArrary}")
        }

        try {
            for (i in 0..parameterColumnInfosNew.size) {
                ret = nativeApi.sqlBindParameter(STMT_handlePtr, UInt16(i + 1), SQL_PARAM_INPUT, paramInfo[i].valueType,
                    paramInfo[i].parameterType, paramInfo[i].columnSize, paramInfo[i].decimalDigits,
                    paramInfo[i].parameterValuePtr, paramInfo[i].bufferLength, paramInfo[i].strLenOrInd)
                if (!SQLSucceeded(ret)) {
                    throw nativeApi.diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
                }
            }

            ret = nativeApi.sqlExecute(STMT_handlePtr)
            if (SQLSucceeded(ret)) {
                return generateUpdateResult()
            } else if (ret == SQL_NO_DATA) {
                return OdbcUpdateResult(0)
            } else {
                throw nativeApi.diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
            }
        } finally {
            freeParamInfo(paramInfo, parameterColumnInfosNew.size)
        }
    }

    /**
     * 执行sql语句，得到查询结果
     *
     * 返回值 QueryResult - 查询结果。
     * 异常 Exception - 传入参数错误。
     */
    public override func query(): QueryResult {
        checkResource()
        let parameterColumnInfosNew: Array<ColumnInfo> = parameterColumnInfos
        var ret: Int16
        if (this.params.isNone() && parameterColumnInfosNew.size > 0) {
            this.params = Array<Any>(parameterColumnInfosNew.size, repeat: Option<Any>.None)
        }
        var paramInfo: Array<ParamInfo> = match (params) {
            case Some(v) => getParamInfo(v)
            case None => Array<ParamInfo>()
        }
        try {
            if (parameterColumnInfosNew.size > 0) {
                for (i in 0..parameterColumnInfosNew.size) {
                    ret = nativeApi.sqlBindParameter(STMT_handlePtr, UInt16(i + 1), SQL_PARAM_INPUT,
                        paramInfo[i].valueType, paramInfo[i].parameterType, paramInfo[i].columnSize,
                        paramInfo[i].decimalDigits, paramInfo[i].parameterValuePtr, paramInfo[i].bufferLength,
                        paramInfo[i].strLenOrInd)
                    if (!SQLSucceeded(ret)) {
                        throw nativeApi.diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
                    }
                }
            }
            ret = nativeApi.sqlExecute(STMT_handlePtr)
            if (SQLSucceeded(ret)) {
                return generateQueryResult()
            } else if (ret == SQL_NO_DATA) {
                return OdbcQueryResult(nativeApi, STMT_handlePtr, Array<OdbcColumnInfo>())
            } else {
                throw nativeApi.diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
            }
        } finally {
            freeParamInfo(paramInfo, parameterColumnInfosNew.size)
        }
    }

    /**
     * 执行 sql 语句，得到更新结果
     * 返回值 UpdateResult - 更新结果。
     * 异常 SqlException - 执行过程中发生了异常，比如网络中断，服务器超时，参数个数不正确
     */
    @Deprecated
    public override func update(params: Array<SqlDbType>): UpdateResult {
        throw UnsupportedException("Deprecated method, use set<T>() + update() instead")
    }

    /**
     * 执行 sql 语句，得到查询结果
     * 返回值 QueryResult - 查询结果。
     * 异常 SqlException - 执行过程中发生了异常，比如网络中断，服务器超时，参数个数不正确
     */
    @Deprecated
    public override func query(params: Array<SqlDbType>): QueryResult {
        throw UnsupportedException("Deprecated method, use set<T>() + query() instead")
    }

    private func getParamInfo(params: Array<Any>): Array<ParamInfo> {
        var paramInfo: Array<ParamInfo> = Array<ParamInfo>(params.size, repeat: ParamInfo())
        for (i in 0..params.size) {
            match (params[i]) {
                case v: ParamInfo => paramInfo[i] = v
                case v: String => paramInfo[i] = setString(v, SQL_CHAR)
                case v: ?String => paramInfo[i] = setString(v, SQL_CHAR)
                case v: Array<Byte> => paramInfo[i] = setBytes(v, SQL_BINARY)
                case v: ?Array<Byte> => paramInfo[i] = setBytes(v, SQL_BINARY)
                case v: InputStream => paramInfo[i] = setBlob(v)
                case v: ?InputStream => paramInfo[i] = setBlob(v)
                case v: Bool => paramInfo[i] = setBool(v)
                case v: ?Bool => paramInfo[i] = setBool(v)
                case v: Int8 => paramInfo[i] = setInt8(v)
                case v: ?Int8 => paramInfo[i] = setInt8(v)
                case v: UInt8 => paramInfo[i] = setUInt8(v)
                case v: ?UInt8 => paramInfo[i] = setUInt8(v)
                case v: Int16 => paramInfo[i] = setInt16(v)
                case v: ?Int16 => paramInfo[i] = setInt16(v)
                case v: UInt16 => paramInfo[i] = setUInt16(v)
                case v: ?UInt16 => paramInfo[i] = setUInt16(v)
                case v: Int32 => paramInfo[i] = setInt32(v)
                case v: ?Int32 => paramInfo[i] = setInt32(v)
                case v: UInt32 => paramInfo[i] = setUInt32(v)
                case v: ?UInt32 => paramInfo[i] = setUInt32(v)
                case v: Int64 => paramInfo[i] = setInt64(v)
                case v: ?Int64 => paramInfo[i] = setInt64(v)
                case v: UInt64 => paramInfo[i] = setUInt64(v)
                case v: ?UInt64 => paramInfo[i] = setUInt64(v)
                case v: Float32 => paramInfo[i] = setFloat32(v)
                case v: ?Float32 => paramInfo[i] = setFloat32(v)
                case v: Float64 => paramInfo[i] = setFloat64(v)
                case v: ?Float64 => paramInfo[i] = setFloat64(v)
                case v: DateTime => paramInfo[i] = setTimestampWithoutTz(v)
                case v: ?DateTime => paramInfo[i] = setTimestampWithoutTz(v)
                case v: Decimal => paramInfo[i] = setDecimal(v, SQL_VARCHAR)
                case v: ?Decimal => paramInfo[i] = setDecimal(v, SQL_VARCHAR)
                case v: BigInt => paramInfo[i] = setBigInt(v)
                case v: ?BigInt => paramInfo[i] = setBigInt(v)
                // null
                case v: ?Any => paramInfo[i] = setNullData(parameterColumnInfos[i])
                case _ => throw SqlException("Unsupported data type.")
            }
        }
        return paramInfo
    }

    private func generateUpdateResult(): OdbcUpdateResult {
        var updateResult: OdbcUpdateResult
        var rowCountPtr = nativeApi.malloc(LEN_MALLOC_8)
        if (rowCountPtr.isNull()) {
            throw SqlException("Native malloc Failed.")
        }
        unsafe { CPointer<Int64>(rowCountPtr).write(0) }
        var ret = nativeApi.sqlRowCount(STMT_handlePtr, CPointer<Int64>(rowCountPtr))
        if (SQLSucceeded(ret)) {
            updateResult = OdbcUpdateResult(unsafe { CPointer<Int64>(rowCountPtr).read() })
        } else {
            nativeApi.free(rowCountPtr)
            throw nativeApi.diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
        }

        nativeApi.free(rowCountPtr)
        return updateResult
    }

    private func getSqlTypeName(dataType: Int16): String {
        match (dataType) {
            case 1 | 12 => return "VARCHAR" // SQL_CHAR| SQL_VARCHAR
            case -2 | -3 => return "VARBINARY" // SQL_BINARY| SQL_VARBINARY
            case -1 => return "CLOB" // SQL_LONGVARCHAR
            case -4 => return "BLOB" // SQL_LONGVARBINARY
            case -6 => return "TINYINT" // SQL_TINYINT
            case 5 => return "SMALLINT" // SQL_SMALLINT
            case 4 => return "INTEGER" // SQL_INTEGER
            case -5 => return "BIGINT" // SQL_BIGINT
            case 7 => return "REAL" // SQL_REAL
            case 8 => return "DOUBLE" // SQL_DOUBLE
            case 91 => return "DATE" // SQL_TYPE_DATE
            case 92 => return "TIME" // SQL_TYPE_TIME
            case 93 => return "TIMESTAMP" // SQL_TYPE_TIMESTAMP
            case 3 => return "DECIMAL" // SQL_DECIMAL
            case _ => return "OTHER"
        }
    }

    private func generateQueryResult(): OdbcQueryResult {
        var queryResult: OdbcQueryResult
        var columnCountPtr = nativeApi.malloc(LEN_MALLOC_2)
        if (columnCountPtr.isNull()) {
            throw SqlException("Native malloc Failed.")
        }
        var ret = nativeApi.sqlNumResultCols(STMT_handlePtr, CPointer<Int16>(columnCountPtr))
        if (SQLSucceeded(ret)) {
            var columnCount = unsafe { CPointer<Int16>(columnCountPtr).read() }
            if (columnCount > 0) {
                var arrOdbcColumnInfo = Array<OdbcColumnInfo>(Int64(columnCount), repeat: OdbcColumnInfo())
                var bufferLength: Int16 = 1024
                var columnNamePtr = unsafe { LibC.malloc<UInt8>(count: Int64(bufferLength)) }
                if (columnNamePtr.isNull()) {
                    nativeApi.free(columnCountPtr)
                    throw SqlException("Native malloc Failed.")
                }
                var columnName = CString(columnNamePtr)
                var nameLengthPtr = nativeApi.malloc(LEN_MALLOC_2)
                if (nameLengthPtr.isNull()) {
                    unsafe { LibC.free<UInt8>(columnNamePtr) }
                    nativeApi.free(columnCountPtr)
                    throw SqlException("Native malloc Failed.")
                }
                var dataTypePtr = nativeApi.malloc(LEN_MALLOC_2)
                if (dataTypePtr.isNull()) {
                    unsafe { LibC.free<UInt8>(columnNamePtr) }
                    nativeApi.free(nameLengthPtr)
                    nativeApi.free(columnCountPtr)
                    throw SqlException("Native malloc Failed.")
                }
                var columnSizePtr = nativeApi.malloc(LEN_MALLOC_8)
                if (columnSizePtr.isNull()) {
                    unsafe { LibC.free<UInt8>(columnNamePtr) }
                    nativeApi.free(columnCountPtr)
                    nativeApi.free(nameLengthPtr)
                    nativeApi.free(dataTypePtr)
                    throw SqlException("Native malloc Failed.")
                }
                var decimalDigitsPtr = nativeApi.malloc(LEN_MALLOC_2)
                if (decimalDigitsPtr.isNull()) {
                    unsafe { LibC.free<UInt8>(columnNamePtr) }
                    nativeApi.free(columnCountPtr)
                    nativeApi.free(nameLengthPtr)
                    nativeApi.free(dataTypePtr)
                    nativeApi.free(columnSizePtr)
                    throw SqlException("Native malloc Failed.")
                }
                var nullablePtr = nativeApi.malloc(LEN_MALLOC_2)
                if (nullablePtr.isNull()) {
                    unsafe { LibC.free<UInt8>(columnNamePtr) }
                    nativeApi.free(columnCountPtr)
                    nativeApi.free(nameLengthPtr)
                    nativeApi.free(dataTypePtr)
                    nativeApi.free(columnSizePtr)
                    nativeApi.free(decimalDigitsPtr)
                    throw SqlException("Native malloc Failed.")
                }
                for (i in 0..columnCount) {
                    var columnNumber = UInt16(i + 1)
                    unsafe {
                        ret = nativeApi.sqlDescribeCol(STMT_handlePtr, columnNumber, columnName, bufferLength,
                            CPointer<Int16>(nameLengthPtr), CPointer<Int16>(dataTypePtr), CPointer<Int64>(columnSizePtr),
                            CPointer<Int16>(decimalDigitsPtr), CPointer<Int16>(nullablePtr))
                        if (SQLSucceeded(ret)) {
                            var typeName: String
                            var dataType = CPointer<Int16>(dataTypePtr).read()
                            var nullable: Int16
                            nullable = CPointer<Int16>(nullablePtr).read()
                            typeName = getSqlTypeName(dataType)
                            var odbcColumnInfo = OdbcColumnInfo(columnName.toString(), typeName,
                                CPointer<Int64>(columnSizePtr).read(), CPointer<Int16>(decimalDigitsPtr).read(), 0,
                                nullable)
                            arrOdbcColumnInfo[Int64(i)] = odbcColumnInfo
                        } else {
                            unsafe { LibC.free<UInt8>(columnNamePtr) }
                            nativeApi.free(columnCountPtr)
                            nativeApi.free(nameLengthPtr)
                            nativeApi.free(dataTypePtr)
                            nativeApi.free(columnSizePtr)
                            nativeApi.free(decimalDigitsPtr)
                            nativeApi.free(nullablePtr)
                            var exception = nativeApi.diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
                            throw exception
                        }
                    }
                }
                unsafe { LibC.free<UInt8>(columnNamePtr) }
                nativeApi.free(nameLengthPtr)
                nativeApi.free(dataTypePtr)
                nativeApi.free(columnSizePtr)
                nativeApi.free(decimalDigitsPtr)
                nativeApi.free(nullablePtr)

                queryResult = OdbcQueryResult(nativeApi, STMT_handlePtr, arrOdbcColumnInfo)
            } else {
                nativeApi.free(columnCountPtr)
                throw nativeApi.diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
            }
        } else {
            nativeApi.free(columnCountPtr)
            throw nativeApi.diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
        }
        nativeApi.free(columnCountPtr)
        return queryResult
    }

    private func setNullData(colInfo: ColumnInfo): ParamInfo {
        var info = ParamInfo()
        var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (strLenOrInd.isNull()) {
            throw SqlException("Native malloc Failed.")
        }
        unsafe { strLenOrInd.write(SQL_NULL_DATA) }
        info.strLenOrInd = strLenOrInd

        let (vt, pt) = match (colInfo.typeName) {
            case "TINYINT" | "SqlInt8" => (SQL_C_TINYINT, SQL_TINYINT)
            case "SMALLINT" | "SqlInt16" => (SQL_C_SHORT, SQL_SMALLINT)
            case "INTEGER" | "SqlInt32" => (SQL_C_LONG, SQL_INTEGER)
            case "BIGINT" | "SqlInt64" => (SQL_C_UBIGINT, SQL_BIGINT)
            case "REAL" | "FLOAT" | "SqlFloat" => (SQL_C_FLOAT, SQL_FLOAT)
            case "DOUBLE" | "SqlDouble" => (SQL_C_DOUBLE, SQL_DOUBLE)
            case "VARCHAR" | "CHAR" | "CLOB" | "DECIMAL" | "SqlString" | "SqlNumeric" => (SQL_C_CHAR, SQL_VARCHAR)
            case "VARBINARY" | "BINARY" | "BLOB" | "SqlBytes" => (SQL_C_BINARY, SQL_VARBINARY)
            case "DATE" | "SqlDate" => (SQL_C_TYPE_DATE, SQL_TYPE_DATE)
            case "TIME" | "SqlTime" => (SQL_C_TYPE_TIME, SQL_TYPE_TIME)
            case "TIMESTAMP" | "SqlTimestamp" => (SQL_C_TYPE_TIMESTAMP, SQL_TYPE_TIMESTAMP)
            case _ => (SQL_C_CHAR, SQL_VARCHAR)
        }
        info.valueType = vt
        info.parameterType = pt
        return info
    }

    private func setString(value: Option<String>, sqlType: Int16): ParamInfo {
        var info = ParamInfo()
        var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (strLenOrInd.isNull()) {
            throw SqlException("Native malloc Failed.")
        }
        info.valueType = SQL_C_CHAR
        info.parameterType = sqlType
        if (value != None) {
            let realValue: String = value ?? "\0"
            var cstr = unsafe { LibC.mallocCString(realValue) }
            var bufferLength = cstr.size()
            var parameterValuePtr = CPointer<Unit>(cstr.getChars())
            unsafe { strLenOrInd.write(Int64(SQL_NTS)) }
            info.parameterValuePtr = parameterValuePtr
            info.bufferLength = bufferLength
            info.strLenOrInd = strLenOrInd
            info.isString = true
            info.cstring = cstr
        } else {
            unsafe { strLenOrInd.write(SQL_NULL_DATA) }
            info.strLenOrInd = strLenOrInd
        }
        return info
    }

    private func setBytes(value: Option<Array<Byte>>, sqlType: Int16): ParamInfo {
        var info = ParamInfo()
        var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (strLenOrInd.isNull()) {
            throw SqlException("Native malloc Failed.")
        }
        info.valueType = SQL_C_BINARY
        info.parameterType = sqlType
        if (value != None) {
            let realValue: Array<Byte> = value ?? []
            var cptrHandle = unsafe { acquireArrayRawData(realValue) }
            var parameterValuePtr = cptrHandle.pointer
            var columnSize = UInt64(max(realValue.size, 1))
            var bufferLength = realValue.size
            unsafe { strLenOrInd.write(bufferLength) }
            info.columnSize = columnSize
            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
            info.bufferLength = bufferLength
            info.strLenOrInd = strLenOrInd
            info.isArrary = true
            info.cptrHand = cptrHandle
        } else {
            unsafe { strLenOrInd.write(SQL_NULL_DATA) }
            info.strLenOrInd = strLenOrInd
        }
        return info
    }

    private func setClob(value: Option<InputStream>): ParamInfo {
        var info = ParamInfo()
        var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (strLenOrInd.isNull()) {
            throw SqlException("Native malloc Failed.")
        }
        info.valueType = SQL_C_CHAR
        info.parameterType = SQL_LONGVARCHAR
        match (value) {
            case Some(v) =>
                var arr: Array<Byte> = Array<Byte>(1, repeat: 0)
                var list: ArrayList<Byte> = ArrayList<Byte>()
                var length: Int64 = 0
                while (true) {
                    var date: Int64 = v.read(arr)
                    if (date == 0) {
                        break
                    }
                    list.add(arr[0])
                    length++
                }
                unsafe {
                    var cp: CPointerHandle<Byte> = acquireArrayRawData<Byte>(list.toArray())
                    info.parameterValuePtr = CPointer<Unit>(cp.pointer)
                    info.cptrHand = cp
                }
                var columnSize = length
                unsafe { strLenOrInd.write(length) }
                info.bufferLength = columnSize
                info.strLenOrInd = strLenOrInd
                info.isString = true
            case None =>
                unsafe { strLenOrInd.write(SQL_NULL_DATA) }
                info.strLenOrInd = strLenOrInd
        }
        return info
    }

    private func setBlob(value: Option<InputStream>): ParamInfo {
        var info = ParamInfo()
        var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (strLenOrInd.isNull()) {
            throw SqlException("Native malloc Failed.")
        }
        info.valueType = SQL_C_BINARY
        info.parameterType = SQL_LONGVARBINARY
        match (value) {
            case Some(v) =>
                var arr: Array<Byte> = Array<Byte>(1, repeat: 0)
                var list: ArrayList<Byte> = ArrayList<Byte>()
                var length: Int64 = 0
                while (true) {
                    var date: Int64 = v.read(arr)
                    if (date == 0) {
                        break
                    }
                    list.add(arr[0])
                    length++
                }
                unsafe {
                    var cp: CPointerHandle<Byte> = acquireArrayRawData<Byte>(list.toArray())
                    info.parameterValuePtr = CPointer<Unit>(cp.pointer)
                    info.cptrHand = cp
                }
                var columnSize = max(length, 1)
                unsafe { strLenOrInd.write(length) }
                info.bufferLength = columnSize
                info.strLenOrInd = strLenOrInd
                info.isArrary = true
            case None =>
                unsafe { strLenOrInd.write(SQL_NULL_DATA) }
                info.strLenOrInd = strLenOrInd
        }
        return info
    }

    private func setBool(value: Option<Bool>): ParamInfo {
        var info = ParamInfo()
        info.valueType = SQL_C_TINYINT
        info.parameterType = SQL_TINYINT
        if (value != None) {
            var parameterValuePtr = CPointer<Byte>(nativeApi.malloc(LEN_MALLOC_1))
            if (parameterValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let realValue: Bool = value.getOrThrow()
            if (realValue) {
                unsafe { parameterValuePtr.write(1) }
            } else {
                unsafe { parameterValuePtr.write(0) }
            }
            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
        } else {
            var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
            if (strLenOrInd.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            unsafe { strLenOrInd.write(SQL_NULL_DATA) }
            info.strLenOrInd = strLenOrInd
        }
        return info
    }

    private func setInt8(value: Option<Int8>): ParamInfo {
        var info = ParamInfo()
        info.valueType = SQL_C_TINYINT
        info.parameterType = SQL_TINYINT
        if (value != None) {
            var parameterValuePtr = CPointer<Int8>(nativeApi.malloc(LEN_MALLOC_1))
            if (parameterValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let realValue: Int8 = value ?? 0
            unsafe { parameterValuePtr.write(realValue) }

            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
        } else {
            var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
            if (strLenOrInd.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            unsafe { strLenOrInd.write(SQL_NULL_DATA) }
            info.strLenOrInd = strLenOrInd
        }
        return info
    }

    @OverflowWrapping
    private func setUInt8(value: Option<UInt8>): ParamInfo {
        var info = ParamInfo()
        info.valueType = SQL_C_TINYINT
        info.parameterType = SQL_TINYINT
        if (value != None) {
            var parameterValuePtr = CPointer<Int8>(nativeApi.malloc(LEN_MALLOC_1))
            if (parameterValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let realValue: Int8 = Int8(value ?? 0)
            unsafe { parameterValuePtr.write(realValue) }

            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
        } else {
            var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
            if (strLenOrInd.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            unsafe { strLenOrInd.write(SQL_NULL_DATA) }
            info.strLenOrInd = strLenOrInd
        }
        return info
    }

    private func setInt16(value: Option<Int16>): ParamInfo {
        var info = ParamInfo()
        // 使用字符串绑定作为临时解决方案，避免 zenith 驱动类型限制
        info.valueType = SQL_C_CHAR
        info.parameterType = SQL_VARCHAR
        if (value != None) {
            let realValue: Int16 = value ?? 0
            let strValue = realValue.toString()
            var cstr = unsafe { LibC.mallocCString(strValue) }
            var bufferLength = cstr.size()
            var parameterValuePtr = CPointer<Unit>(cstr.getChars())
            var strLenOrIndPtr = nativeApi.malloc(LEN_MALLOC_8)
            if (strLenOrIndPtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            unsafe {
                CPointer<Int64>(strLenOrIndPtr).write(Int64(SQL_NTS))
                info.strLenOrInd = CPointer<Int64>(strLenOrIndPtr)
            }
            info.parameterValuePtr = parameterValuePtr
            info.bufferLength = bufferLength
            info.isString = true
            info.cstring = cstr
        } else {
            var strLenOrIndPtr = nativeApi.malloc(LEN_MALLOC_8)
            if (strLenOrIndPtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            unsafe {
                CPointer<Int64>(strLenOrIndPtr).write(SQL_NULL_DATA)
                info.strLenOrInd = CPointer<Int64>(strLenOrIndPtr)
            }
        }
        return info
    }

    @OverflowWrapping
    private func setUInt16(value: Option<UInt16>): ParamInfo {
        var info = ParamInfo()
        info.valueType = SQL_C_SHORT
        info.parameterType = SQL_SMALLINT
        if (value != None) {
            var parameterValuePtr = CPointer<Int16>(nativeApi.malloc(LEN_MALLOC_2))
            if (parameterValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let realValue: Int16 = Int16(value ?? 0)
            unsafe { parameterValuePtr.write(realValue) }
            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
        } else {
            var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
            if (strLenOrInd.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            unsafe { strLenOrInd.write(SQL_NULL_DATA) }
            info.strLenOrInd = strLenOrInd
        }
        return info
    }

    private func setInt32(value: Option<Int32>): ParamInfo {
        var info = ParamInfo()
        info.valueType = SQL_C_LONG
        info.parameterType = SQL_INTEGER
        if (value != None) {
            var parameterValuePtr = CPointer<Int32>(nativeApi.malloc(LEN_MALLOC_4))
            if (parameterValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let realValue: Int32 = value ?? 0
            unsafe { parameterValuePtr.write(realValue) }
            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
        } else {
            var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
            if (strLenOrInd.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            unsafe { strLenOrInd.write(SQL_NULL_DATA) }
            info.strLenOrInd = strLenOrInd
        }
        return info
    }

    @OverflowWrapping
    private func setUInt32(value: Option<UInt32>): ParamInfo {
        var info = ParamInfo()
        info.valueType = SQL_C_LONG
        info.parameterType = SQL_INTEGER
        if (value != None) {
            var parameterValuePtr = CPointer<Int32>(nativeApi.malloc(LEN_MALLOC_4))
            if (parameterValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let realValue: Int32 = Int32(value ?? 0)
            unsafe { parameterValuePtr.write(realValue) }
            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
        } else {
            var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
            if (strLenOrInd.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            unsafe { strLenOrInd.write(SQL_NULL_DATA) }
            info.strLenOrInd = strLenOrInd
        }
        return info
    }

    private func setInt64(value: Option<Int64>): ParamInfo {
        var info = ParamInfo()
        info.valueType = SQL_C_UBIGINT
        info.parameterType = SQL_BIGINT
        if (value != None) {
            var parameterValuePtr = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
            if (parameterValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let realValue: Int64 = value ?? 0
            unsafe { parameterValuePtr.write(realValue) }
            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
        } else {
            var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
            if (strLenOrInd.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            unsafe { strLenOrInd.write(SQL_NULL_DATA) }
            info.strLenOrInd = strLenOrInd
        }
        return info
    }

    @OverflowWrapping
    private func setUInt64(value: Option<UInt64>): ParamInfo {
        var info = ParamInfo()
        info.valueType = SQL_C_UBIGINT
        info.parameterType = SQL_BIGINT
        if (value != None) {
            var parameterValuePtr = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
            if (parameterValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let realValue: Int64 = Int64(value ?? 0)
            unsafe { parameterValuePtr.write(realValue) }
            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
        } else {
            var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
            if (strLenOrInd.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            unsafe { strLenOrInd.write(SQL_NULL_DATA) }
            info.strLenOrInd = strLenOrInd
        }
        return info
    }

    private func setFloat32(value: Option<Float32>): ParamInfo {
        var info = ParamInfo()
        info.valueType = SQL_C_FLOAT
        info.parameterType = SQL_FLOAT // Use SQL_FLOAT instead of SQL_REAL for GaussDB compatibility
        if (value != None) {
            var parameterValuePtr = CPointer<Float32>(nativeApi.malloc(LEN_MALLOC_4))
            if (parameterValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let realValue: Float32 = value ?? 0.0
            unsafe { parameterValuePtr.write(realValue) }
            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
            info.bufferLength = Int64(LEN_MALLOC_4)
            var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
            if (strLenOrInd.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            unsafe { strLenOrInd.write(Int64(LEN_MALLOC_4)) }
            info.strLenOrInd = strLenOrInd
        } else {
            var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
            if (strLenOrInd.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            unsafe { strLenOrInd.write(SQL_NULL_DATA) }
            info.strLenOrInd = strLenOrInd
        }
        return info
    }

    private func setFloat64(value: Option<Float64>): ParamInfo {
        var info = ParamInfo()
        info.valueType = SQL_C_DOUBLE
        info.parameterType = SQL_DOUBLE
        if (value != None) {
            var parameterValuePtr = CPointer<Float64>(nativeApi.malloc(LEN_MALLOC_8))
            if (parameterValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let realValue: Float64 = value ?? 0.0
            unsafe { parameterValuePtr.write(realValue) }
            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
            info.bufferLength = Int64(LEN_MALLOC_8)
            var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
            if (strLenOrInd.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            unsafe { strLenOrInd.write(Int64(LEN_MALLOC_8)) }
            info.strLenOrInd = strLenOrInd
        } else {
            var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
            if (strLenOrInd.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            unsafe { strLenOrInd.write(SQL_NULL_DATA) }
            info.strLenOrInd = strLenOrInd
        }
        return info
    }

    private func setTimestampWithoutTz(value: Option<DateTime>): ParamInfo {
        var info = ParamInfo()
        info.valueType = SQL_C_TYPE_TIMESTAMP
        info.parameterType = SQL_TYPE_TIMESTAMP
        if (value != None) {
            var parameterValuePtr = CPointer<TIMESTAMP_STRUCT>(nativeApi.malloc(LEN_MALLOC_16))
            if (parameterValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let realValue: DateTime = value.getOrThrow()
            var timestamp = TIMESTAMP_STRUCT()
            timestamp.year = Int16(realValue.year)
            timestamp.month = Int16(realValue.month.toInteger())
            timestamp.day = Int16(realValue.dayOfMonth)
            timestamp.hour = Int16(realValue.hour)
            timestamp.minute = Int16(realValue.minute)
            timestamp.second = Int16(realValue.second)
            timestamp.fraction = UInt32(realValue.nanosecond)
            unsafe { parameterValuePtr.write(timestamp) }
            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
        } else {
            var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
            if (strLenOrInd.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            unsafe { strLenOrInd.write(SQL_NULL_DATA) }
            info.strLenOrInd = strLenOrInd
        }
        return info
    }

    private func setDecimal(value: Option<Decimal>, sqlType: Int16): ParamInfo {
        var info = ParamInfo()
        var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (strLenOrInd.isNull()) {
            throw SqlException("Native malloc Failed.")
        }
        info.valueType = SQL_C_CHAR
        info.parameterType = sqlType
        if (value != None) {
            let realValue: String = (value ?? Decimal(0)).toString()
            var cstr = unsafe { LibC.mallocCString(realValue) }
            var bufferLength = cstr.size()
            var parameterValuePtr = CPointer<Unit>(cstr.getChars())
            unsafe { strLenOrInd.write(Int64(SQL_NTS)) }

            info.parameterValuePtr = parameterValuePtr
            info.bufferLength = bufferLength
            info.strLenOrInd = strLenOrInd
            info.isString = true
            info.cstring = cstr
        } else {
            unsafe { strLenOrInd.write(SQL_NULL_DATA) }
            info.strLenOrInd = strLenOrInd
        }
        return info
    }

    private func setBigInt(value: Option<BigInt>): ParamInfo {
        var info = ParamInfo()
        var strLenOrInd = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (strLenOrInd.isNull()) {
            throw SqlException("Native malloc Failed.")
        }
        info.valueType = SQL_C_CHAR
        info.parameterType = SQL_VARCHAR
        if (value != None) {
            let realValue: String = (value ?? BigInt(0)).toString()
            var cstr = unsafe { LibC.mallocCString(realValue) }
            var bufferLength = cstr.size()
            var parameterValuePtr = CPointer<Unit>(cstr.getChars())
            unsafe { strLenOrInd.write(Int64(SQL_NTS)) }

            info.parameterValuePtr = parameterValuePtr
            info.bufferLength = bufferLength
            info.strLenOrInd = strLenOrInd
            info.isString = true
            info.cstring = cstr
        } else {
            unsafe { strLenOrInd.write(SQL_NULL_DATA) }
            info.strLenOrInd = strLenOrInd
        }
        return info
    }

    public override func close(): Unit {
        if (isClosed()) {
            return
        }
        nativeApi.sqlCloseCursor(this.STMT_handlePtr)
        nativeApi.sqlFreeHandle(SQL_HANDLE_STMT, this.STMT_handlePtr)
        closed.store(true)
    }

    public override func isClosed(): Bool {
        return closed.load()
    }

    public func getStmtHandle(): CPointer<Unit> {
        unsafe { return this.STMT_handlePtr }
    }

    private func freeParamInfo(paramInfo: Array<ParamInfo>, count: Int64): Unit {
        for (i in 0..count) {
            unsafe {
                if (!paramInfo[i].strLenOrInd.isNull()) {
                    nativeApi.free(CPointer<Unit>(paramInfo[i].strLenOrInd))
                }
                if (paramInfo[i].isArrary || paramInfo[i].isString) {
                    releaseArrayRawData(paramInfo[i].cptrHand)
                } else if (!paramInfo[i].parameterValuePtr.isNull()) {
                    nativeApi.free(paramInfo[i].parameterValuePtr)
                }
            }
        }
    }

    private func checkResource() {
        if (isClosed()) {
            throw SqlException("The Statement has been closed")
        }
    }
}
