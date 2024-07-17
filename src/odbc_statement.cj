/*
 * @Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights reserved.
 */
 
package odbc4cj

public class OdbcStatement <: Statement {
    private var STMT_handlePtr: CPointer<Unit>
    private let closed = AtomicBool(false)

    init(STMT_handlePtr: CPointer<Unit>) {
        this.STMT_handlePtr = STMT_handlePtr
    }

    /*
     * 预执行sql语句中，占位参数的列信息，比如列名，列类型，列长度，是否允许数据库Null值等
     */
    public override prop parameterColumnInfos: Array<ColumnInfo> {
        get() {
            var ParameterCountPtr = LibC.malloc<Int16>()
            if (ParameterCountPtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            unsafe {
                ParameterCountPtr.write(0)
                var ret = SQLNumParams(STMT_handlePtr, ParameterCountPtr)
                if (!SQLSucceeded(ret)) {
                    var exception = diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
                    unsafe { LibC.free<Int16>(ParameterCountPtr) }
                    throw exception
                }
                var len = CPointer<Int16>(ParameterCountPtr).read()
                LibC.free<Int16>(ParameterCountPtr)
                if (len != 0) {
                    var arrInfo: Array<ColumnInfo> = Array<ColumnInfo>(Int64(len), item: OdbcColumnInfo())
                    var parameterSizePtr = LibC.malloc<Int64>()
                    var dataTypePtr = LibC.malloc<Int16>()
                    var decimalDigitsPtr = LibC.malloc<Int16>()
                    var nullablePtr = LibC.malloc<Int16>()
                    for (i in 0..len) {
                        var parameterNumber = i + 1
                        unsafe {
                            ret = SQLDescribeParam(STMT_handlePtr, parameterNumber, dataTypePtr, parameterSizePtr,
                                                decimalDigitsPtr, nullablePtr)
                            if (!SQLSucceeded(ret)) {
                                var exception = diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
                                LibC.free<Int64>(parameterSizePtr)
                                LibC.free<Int16>(dataTypePtr)
                                LibC.free<Int16>(decimalDigitsPtr)
                                LibC.free<Int16>(nullablePtr)
                                throw exception
                            }
                            var nullable = nullablePtr.read()
                            var typeName = getSqlTypeName(dataTypePtr.read(), nullable)
                            var odbcColumnInfo = OdbcColumnInfo("", typeName, parameterSizePtr.read(),
                                                                decimalDigitsPtr.read(), 0, nullable)
                            arrInfo[Int64(i)] = odbcColumnInfo
                        }
                    }
                    unsafe {
                        LibC.free<Int64>(parameterSizePtr)
                        LibC.free<Int16>(dataTypePtr)
                        LibC.free<Int16>(decimalDigitsPtr)
                        LibC.free<Int16>(nullablePtr)
                    }
                    return arrInfo
                } else {
                    return Array<ColumnInfo>()
                }
            }
        }
    }

    /**
     * 设置预执行 sql 语句选项
     */
    public override func setOption(key: String, value: String): Unit {
    }

    /**
     * 设置预执行 sql 语句选项
     */
    public func setOption(key: Int32, value: Int64): Unit {
        var ret = unsafe { SQLSetConnectAttr(STMT_handlePtr, key, value, SQL_IS_INTEGER) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
            throw exception
        }
    }

    /**
     * 执行 sql 语句，得到更新结果
     * 返回值 UpdateResult - 更新结果。
     * 异常 SqlException - 执行过程中发生了异常，比如网络中断，服务器超时，参数个数不正确
     */
    public override func update(params: Array<SqlDbType>): OdbcUpdateResult {
        var ret: Int16
        var result: OdbcUpdateResult
        var paramInfo = getParamInfo(params)

        for (i in 0..params.size) {
            ret = unsafe { SQLBindParameter(STMT_handlePtr,
                                            i + 1,
                                            SQL_PARAM_INPUT,
                                            paramInfo[i].valueType,
                                            paramInfo[i].parameterType,
                                            paramInfo[i].columnSize,
                                            paramInfo[i].decimalDigits,
                                            paramInfo[i].parameterValuePtr,
                                            paramInfo[i].bufferLength,
                                            paramInfo[i].strLenOrInd)
            }

            if (!SQLSucceeded(ret)) {
                diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
            }
        }

        ret = unsafe { SQLExecute(STMT_handlePtr) }
        if (SQLSucceeded(ret)) {
            result = generateUpdateResult()
        } else if (ret == SQL_NO_DATA) {
            result = OdbcUpdateResult(0)
        } else {
            diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
            result = OdbcUpdateResult(0)
        }

        for (i in 0..params.size) {
            unsafe {
                if (!paramInfo[i].strLenOrInd.isNull()) {
                    free(CPointer<Unit>(paramInfo[i].strLenOrInd))
                }

                if (paramInfo[i].isArrary || paramInfo[i].isString) {
                    releaseArrayRawData(paramInfo[i].cptrHand)
                } else {
                    free(paramInfo[i].parameterValuePtr)
                }
            }
        }

        return result
    }

    /**
     * 执行 sql 语句，得到查询结果
     * 返回值 QueryResult - 查询结果。
     * 异常 SqlException - 执行过程中发生了异常，比如网络中断，服务器超时，参数个数不正确
     */
    public override func query(params: Array<SqlDbType>): OdbcQueryResult {
        var ret: Int16

        if (parameterColumnInfos.size > params.size) {
            throw SqlException("Parameter count isn't ${parameterColumnInfos.size}.")
        } else if (parameterColumnInfos.size > 0) {
            var paramInfo = getParamInfo(params)
            for (i in 0..parameterColumnInfos.size) {
                ret = unsafe { SQLBindParameter(STMT_handlePtr,
                                                i + 1,
                                                SQL_PARAM_INPUT,
                                                paramInfo[i].valueType,
                                                paramInfo[i].parameterType,
                                                paramInfo[i].columnSize,
                                                paramInfo[i].decimalDigits,
                                                paramInfo[i].parameterValuePtr,
                                                paramInfo[i].bufferLength,
                                                paramInfo[i].strLenOrInd)
                }

                if (!SQLSucceeded(ret)) {
                    diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
                }
            }
        }

        ret = unsafe { SQLExecute(STMT_handlePtr) }
        if (SQLSucceeded(ret)) {
            return generateQueryResult()
        } else {
            diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
            return OdbcQueryResult(STMT_handlePtr, Array<OdbcColumnInfo>())
        }
    }

    private func getParamInfo(params: Array<SqlDbType>): Array<ParamInfo> {
        var paramInfo = Array<ParamInfo>(params.size, item: ParamInfo())
        for (i in 0..params.size) {
            match (params[i]) {
                case v: SqlChar => paramInfo[i] = setString(v.value, SQL_CHAR)
                case v: SqlNullableChar => paramInfo[i] = setString(v.value, SQL_CHAR)
                case v: SqlVarchar => paramInfo[i] = setString(v.value, SQL_VARCHAR)
                case v: SqlNullableVarchar => paramInfo[i] = setString(v.value, SQL_VARCHAR)
                case v: SqlBinary => paramInfo[i] = setBytes(v.value, SQL_BINARY)
                case v: SqlNullableBinary => paramInfo[i] = setBytes(v.value, SQL_BINARY)
                case v: SqlVarBinary => paramInfo[i] = setBytes(v.value, SQL_VARBINARY)
                case v: SqlNullableVarBinary => paramInfo[i] = setBytes(v.value, SQL_VARBINARY)
                case v: SqlClob => paramInfo[i] = setClob(v.value)
                case v: SqlNullableClob => paramInfo[i] = setClob(v.value)
                case v: SqlBlob => paramInfo[i] = setBlob(v.value)
                case v: SqlNullableBlob => paramInfo[i] = setBlob(v.value)
                case v: SqlBool => paramInfo[i] = setBool(v.value)
                case v: SqlNullableBool => paramInfo[i] = setBool(v.value)
                case v: SqlByte => paramInfo[i] = setInt8(v.value)
                case v: SqlNullableByte => paramInfo[i] = setInt8(v.value)
                case v: SqlSmallInt => paramInfo[i] = setInt16(v.value)
                case v: SqlNullableSmallInt => paramInfo[i] = setInt16(v.value)
                case v: SqlInteger => paramInfo[i] = setInt32(v.value)
                case v: SqlNullableInteger => paramInfo[i] = setInt32(v.value)
                case v: SqlBigInt => paramInfo[i] = setInt64(v.value)
                case v: SqlNullableBigInt => paramInfo[i] = setInt64(v.value)
                case v: SqlReal => paramInfo[i] = setFloat32(v.value)
                case v: SqlNullableReal => paramInfo[i] = setFloat32(v.value)
                case v: SqlDouble => paramInfo[i] = setFloat64(v.value)
                case v: SqlNullableDouble => paramInfo[i] = setFloat64(v.value)
                case v: SqlDate => paramInfo[i] = setDate(v.value)
                case v: SqlNullableDate => paramInfo[i] = setDate(v.value)
                case v: SqlTime => paramInfo[i] = setTime(v.value)
                case v: SqlNullableTime => paramInfo[i] = setTime(v.value)
                case v: SqlTimestampWithoutTz => paramInfo[i] = setTimestampWithoutTz(v.value)
                case v: SqlNullableTimestampWithoutTz => paramInfo[i] = setTimestampWithoutTz(v.value)
                case v: SqlDecimal => paramInfo[i] = setDecimal(v.value, SQL_VARCHAR)
                case v: SqlNullableDecimal => paramInfo[i] = setDecimal(v.value, SQL_VARCHAR)
                case _ => throw SqlException("Unsupported data type.")
            }
        }

        return paramInfo
    }

    private func generateUpdateResult(): OdbcUpdateResult {
        var updateResult: OdbcUpdateResult
        var rowCountPtr = LibC.malloc<Int64>()
        unsafe { rowCountPtr.write(0) }
        var ret = unsafe { SQLRowCount(STMT_handlePtr, rowCountPtr) }
        if (SQLSucceeded(ret)) {
            updateResult = OdbcUpdateResult(unsafe { rowCountPtr.read() })
        }  else {
            diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
            updateResult = OdbcUpdateResult(0)
        }

        unsafe { LibC.free<Int64>(rowCountPtr) }
        return updateResult
    }

    private func getSqlTypeName(dataType: Int16, nullable: Int16): String {
        var typeName: String
        if (dataType == SQL_CHAR) {
            if (nullable == SQL_NO_NULLS) {
                typeName = "SqlChar"
            } else {
                typeName = "SqlNullableChar"
            }
        } else if (dataType == SQL_VARCHAR) {
            if (nullable == SQL_NO_NULLS) {
                typeName = "SqlVarchar"
            } else {
                typeName = "SqlNullableVarchar"
            }
        } else if (dataType == SQL_BINARY) {
            if (nullable == SQL_NO_NULLS) {
                typeName = "SqlBinary"
            } else {
                typeName = "SqlNullableBinary"
            }
        } else if (dataType == SQL_VARBINARY) {
            if (nullable == SQL_NO_NULLS) {
                typeName = "SqlVarBinary"
            } else {
                typeName = "SqlNullableVarBinary"
            }
        } else if (dataType == SQL_LONGVARCHAR) {
            if (nullable == SQL_NO_NULLS) {
                typeName = "SqlClob"
            } else {
                typeName = "SqlNullableClob"
            }
        } else if (dataType == SQL_LONGVARBINARY) {
            if (nullable == SQL_NO_NULLS) {
                typeName = "SqlBlob"
            } else {
                typeName = "SqlNullableBlob"
            }
        } else if (dataType == SQL_TINYINT) {
            if (nullable == SQL_NO_NULLS) {
                typeName = "SqlByte"
            } else {
                typeName = "SqlNullableByte"
            }
        } else if (dataType == SQL_SMALLINT) {
            if (nullable == SQL_NO_NULLS) {
                typeName = "SqlSmallInt"
            } else {
                typeName = "SqlNullableSmallInt"
            }
        } else if (dataType == SQL_INTEGER) {
            if (nullable == SQL_NO_NULLS) {
                typeName = "SqlInteger"
            } else {
                typeName = "SqlNullableInteger"
            }
        } else if (dataType == SQL_BIGINT) {
            if (nullable == SQL_NO_NULLS) {
                typeName = "SqlBigInt"
            } else {
                typeName = "SqlNullableBigInt"
            }
        } else if (dataType == SQL_REAL) {
            if (nullable == SQL_NO_NULLS) {
                typeName = "SqlReal"
            } else {
                typeName = "SqlNullableReal"
            }
        } else if (dataType == SQL_DOUBLE) {
            if (nullable == SQL_NO_NULLS) {
                typeName = "SqlDouble"
            } else {
                typeName = "SqlNullableDouble"
            }
        } else if (dataType == SQL_TYPE_DATE) {
            if (nullable == SQL_NO_NULLS) {
                typeName = "SqlDate"
            } else {
                typeName = "SqlNullableDate"
            }
        } else if (dataType == SQL_TYPE_TIME) {
            if (nullable == SQL_NO_NULLS) {
                typeName = "SqlTime"
            } else {
                typeName = "SqlNullableTime"
            }
        } else if (dataType == SQL_TYPE_TIMESTAMP) {
            if (nullable == SQL_NO_NULLS) {
                typeName = "SqlTimestampWithoutTz"
            } else {
                typeName = "SqlNullableTimestampWithoutTz"
            }
        } else if (dataType == SQL_DECIMAL) {
            if (nullable == SQL_NO_NULLS) {
                typeName = "SqlDecimal"
            } else {
                typeName = "SqlNullableDecimal"
            }
        } else {
            throw SqlException("Unknown type ${dataType}, please add type attribute.")
        }

        return typeName
    }

    private func generateQueryResult(): OdbcQueryResult {
        var queryResult: OdbcQueryResult
        var columnCountPtr = unsafe { LibC.malloc<Int16>() }

        var ret = unsafe { SQLNumResultCols(STMT_handlePtr, columnCountPtr) }
        if (SQLSucceeded(ret)) {
            var columnCount = unsafe { columnCountPtr.read() }
            if (columnCount > 0) {
                var arrOdbcColumnInfo = Array<OdbcColumnInfo>(Int64(columnCount), item: OdbcColumnInfo())
                var bufferLength: Int16 = 1024
                var columnNamePtr = LibC.malloc<UInt8>(count: Int64(bufferLength))
                var columnName = CString(columnNamePtr)
                var nameLengthPtr = LibC.malloc<Int16>()
                var dataTypePtr = LibC.malloc<Int16>()
                var columnSizePtr = LibC.malloc<Int64>()
                var decimalDigitsPtr = LibC.malloc<Int16>()
                var nullablePtr = LibC.malloc<Int16>()
                for (i in 0..columnCount) {
                    var columnNumber = i + 1
                    unsafe {
                        ret = SQLDescribeCol(STMT_handlePtr, columnNumber, columnName, bufferLength, nameLengthPtr,
                                             dataTypePtr, columnSizePtr, decimalDigitsPtr, nullablePtr)
                        if (SQLSucceeded(ret)) {
                            var typeName: String
                            var dataType = dataTypePtr.read()
                            var nullable: Int16
                            nullable = nullablePtr.read()
                            typeName = getSqlTypeName(dataType, nullable)
                            var odbcColumnInfo = OdbcColumnInfo(columnName.toString(), typeName, columnSizePtr.read(),
                                                                decimalDigitsPtr.read(), 0, nullable)
                            arrOdbcColumnInfo[Int64(i)] = odbcColumnInfo
                        } else {
                            LibC.free<UInt8>(columnNamePtr)
                            LibC.free<Int16>(nameLengthPtr)
                            LibC.free<Int16>(dataTypePtr)
                            LibC.free<Int64>(columnSizePtr)
                            LibC.free<Int16>(decimalDigitsPtr)
                            LibC.free<Int16>(nullablePtr)
                            var exception = diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
                            throw exception
                        }
                    }
                }

                unsafe {
                    LibC.free<UInt8>(columnNamePtr)
                    LibC.free<Int16>(nameLengthPtr)
                    LibC.free<Int16>(dataTypePtr)
                    LibC.free<Int64>(columnSizePtr)
                    LibC.free<Int16>(decimalDigitsPtr)
                    LibC.free<Int16>(nullablePtr)
                }
                queryResult = OdbcQueryResult(STMT_handlePtr, arrOdbcColumnInfo)
            } else {
                diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
                queryResult = OdbcQueryResult(STMT_handlePtr, Array<OdbcColumnInfo>())
            }
        }  else {
            diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
            queryResult = OdbcQueryResult(STMT_handlePtr, Array<OdbcColumnInfo>())
        }

        unsafe { LibC.free(columnCountPtr) }
        return queryResult
    }

    private func setString(value: Option<String>, sqlType: Int16): ParamInfo {
        var info = ParamInfo()
        var strLenOrInd = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
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
        var strLenOrInd = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
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
        var strLenOrInd = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (strLenOrInd.isNull()) {
            throw SqlException("Native malloc Failed.")
        }

        info.valueType = SQL_C_CHAR
        info.parameterType = SQL_LONGVARCHAR

        match(value) {
            case Some(v) =>
                var arr: Array<Byte> = Array<Byte>(1, item: 0)
                var list: ArrayList<Byte> = ArrayList<Byte>()
                var length: Int64 = 0
                while (true) {
                    var date: Int64 = v.read(arr)
                    if (date == 0) {
                        break
                    }
                    list.append(arr[0])
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
        var strLenOrInd = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (strLenOrInd.isNull()) {
            throw SqlException("Native malloc Failed.")
        }

        info.valueType = SQL_C_BINARY
        info.parameterType = SQL_LONGVARBINARY

        match(value) {
            case Some(v) =>
                var arr: Array<Byte> = Array<Byte>(1, item: 0)
                var list: ArrayList<Byte> = ArrayList<Byte>()
                var length: Int64 = 0
                while (true) {
                    var date: Int64 = v.read(arr)
                    if (date == 0) {
                        break
                    }
                    list.append(arr[0])
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

        info.valueType = SQL_C_STINYINT
        info.parameterType = SQL_TINYINT

        if (value != None) {
            var parameterValuePtr = CPointer<Byte>(unsafe { malloc(LEN_MALLOC_1) })
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
            var strLenOrInd = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
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

        info.valueType = SQL_C_STINYINT
        info.parameterType = SQL_TINYINT

        if (value != None) {
            var parameterValuePtr = CPointer<Int8>(unsafe { malloc(LEN_MALLOC_1) })
            if (parameterValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let realValue: Int8 = value ?? 0
            unsafe { parameterValuePtr.write(realValue) }

            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
        } else {
            var strLenOrInd = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
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

        info.valueType = SQL_C_SSHORT
        info.parameterType = SQL_SMALLINT

        if (value != None) {
            var parameterValuePtr = CPointer<Int16>(unsafe { malloc(LEN_MALLOC_2) })
            if (parameterValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let realValue: Int16 = value ?? 0
            unsafe { parameterValuePtr.write(realValue) }
            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
        } else {
            var strLenOrInd = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
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

        info.valueType = SQL_C_SLONG
        info.parameterType = SQL_INTEGER

        if (value != None) {
            var parameterValuePtr = CPointer<Int32>(unsafe { malloc(LEN_MALLOC_4) })
            if (parameterValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let realValue: Int32 = value ?? 0
            unsafe { parameterValuePtr.write(realValue) }
            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
        } else {
            var strLenOrInd = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
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

        info.valueType = SQL_C_SBIGINT
        info.parameterType = SQL_BIGINT

        if (value != None) {
            var parameterValuePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
            if (parameterValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let realValue: Int64 = value ?? 0
            unsafe { parameterValuePtr.write(realValue) }
            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
        } else {
            var strLenOrInd = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
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
        info.parameterType = SQL_REAL

        if (value != None) {
            var parameterValuePtr = CPointer<Float32>(unsafe { malloc(LEN_MALLOC_4) })
            if (parameterValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let realValue: Float32 = value ?? 0.0
            unsafe { parameterValuePtr.write(realValue) }
            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
        } else {
            var strLenOrInd = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
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
            var parameterValuePtr = CPointer<Float64>(unsafe { malloc(LEN_MALLOC_8) })
            if (parameterValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let realValue: Float64 = value ?? 0.0
            unsafe { parameterValuePtr.write(realValue) }
            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
        } else {
            var strLenOrInd = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
            if (strLenOrInd.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            unsafe { strLenOrInd.write(SQL_NULL_DATA) }
            info.strLenOrInd = strLenOrInd
        }

        return info
    }

    private func setDate(value: Option<DateTime>): ParamInfo {
        var info = ParamInfo()

        info.valueType = SQL_C_TYPE_DATE
        info.parameterType = SQL_TYPE_DATE

        if (value != None) {
            var parameterValuePtr = CPointer<DATE_STRUCT>(unsafe { malloc(LEN_MALLOC_6) })
            if (parameterValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let realValue: DateTime = value.getOrThrow()
            var date = DATE_STRUCT()
            date.year = Int16(realValue.year)
            date.month = Int16(realValue.monthValue)
            date.day = Int16(realValue.dayOfMonth)

            unsafe { parameterValuePtr.write(date) }
            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
        } else {
            var strLenOrInd = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
            if (strLenOrInd.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            unsafe { strLenOrInd.write(SQL_NULL_DATA) }
            info.strLenOrInd = strLenOrInd
        }

        return info
    }

    private func setTime(value: Option<DateTime>): ParamInfo {
        var info = ParamInfo()

        info.valueType = SQL_C_TYPE_TIME
        info.parameterType = SQL_TYPE_TIME

        if (value != None) {
            var parameterValuePtr = CPointer<TIME_STRUCT>(unsafe { malloc(LEN_MALLOC_6) })
            if (parameterValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let realValue: DateTime = value.getOrThrow()
            var time = TIME_STRUCT()
            time.hour = Int16(realValue.hour)
            time.minute = Int16(realValue.minute)
            time.second = Int16(realValue.second)
            unsafe { parameterValuePtr.write(time) }
            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
        } else {
            var strLenOrInd = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
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
            var parameterValuePtr = CPointer<TIMESTAMP_STRUCT>(unsafe { malloc(LEN_MALLOC_16) })
            if (parameterValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let realValue: DateTime = value.getOrThrow()
            var timestamp = TIMESTAMP_STRUCT()
            timestamp.year = Int16(realValue.year)
            timestamp.month = Int16(realValue.monthValue)
            timestamp.day = Int16(realValue.dayOfMonth)
            timestamp.hour = Int16(realValue.hour)
            timestamp.minute = Int16(realValue.minute)
            timestamp.second = Int16(realValue.second)
            timestamp.fraction = UInt32(realValue.nanosecond)
            unsafe { parameterValuePtr.write(timestamp) }
            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
        } else {
            var strLenOrInd = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
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
        var strLenOrInd = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
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

    public override func close(): Unit {
        if (isClosed()) {
            return
        }
        closed.store(true)
        unsafe {
            SQLCloseCursor(this.STMT_handlePtr)
            SQLFreeHandle(SQL_HANDLE_STMT, this.STMT_handlePtr)
        }
    }

    public override func isClosed(): Bool {
        return closed.load()
    }

    public func getStmtHandle(): CPointer<Unit> {
        unsafe { return this.STMT_handlePtr }
    }
}
