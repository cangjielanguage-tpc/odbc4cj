/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
 */

package odbc

struct ParamInfo {
    var valueType: Int16 = 0
    var parameterType: Int16 = 0
    var columnSize: UInt64 = 0
    var decimalDigits: Int16 = 0
    var parameterValuePtr: CPointer<Unit> = CPointer<Unit>()
    var bufferLength: Int64 = 0
    var strLenOrInd: CPointer<Int64> = CPointer<Int64>()
    var isString: Bool = false
    var string: String = String()
    var isArrary: Bool = false
    var cptrHand: CPointerHandle<UInt8> = CPointerHandle<UInt8>()
}

public class OdbcStatement <: Statement {
    private var STMT_handlePtr: CPointer<Unit>

    public init(STMT_handlePtr: CPointer<Unit>) {
        this.STMT_handlePtr = STMT_handlePtr
    }

    /*
     * 预执行 sql 语句中，占位的参数个数
     */
    public prop parameterCount: Int64 {
        get() {
            var ParameterCountPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_2) })
            if (ParameterCountPtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }

            unsafe {
                CPointer<Int16>(ParameterCountPtr).write(0)
                var ret = SQLNumParams(STMT_handlePtr, ParameterCountPtr)
                if (!SQLSucceeded(ret)) {
                    DiagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
                    unsafe { free(ParameterCountPtr) }
                    throw SqlException("Get parameterCount Failed.")
                }

                var res = Int64(CPointer<Int16>(ParameterCountPtr).read())
                unsafe { free(ParameterCountPtr) }
                return res
            }
        }
    }

    /**
     * 设置预执行 sql 语句选项
     */
    public func setOption(key: String, value: String): Unit {
    }

    /**
     * 设置预执行 sql 语句选项
     */
    public func setOption(key: Int32, value: Int64): Unit {
        var ret = unsafe { SQLSetConnectAttr(STMT_handlePtr, key, value, SQL_IS_INTEGER) }
        if (!SQLSucceeded(ret)) {
            unsafe { DiagnoseException(SQL_HANDLE_STMT, STMT_handlePtr) }
            println("setOption Failed.")
        }
    }

    /**
     * 执行 sql 语句，得到更新结果
     * 返回值 UpdateResult - 更新结果。
     * 异常 SqlException - 执行过程中发生了异常，比如网络中断，服务器超时，参数个数不正确
     */
    public func update(params: Array<SqlDbType>): OdbcUpdateResult {
        var ret: Int16
        var result: OdbcUpdateResult

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
                case v: SqlIntger => paramInfo[i] = setInt32(v.value)
                case v: SqlNullableIntger => paramInfo[i] = setInt32(v.value)
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
                case _ => throw SqlException("Unsupported data type.")
            }
        }

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
                DiagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
            }
        }

        ret = unsafe { SQLExecute(STMT_handlePtr) }
        if (SQLSucceeded(ret)) {
            result = generateUpdateResult()
        } else if (ret == SQL_NO_DATA) {
            result = OdbcUpdateResult(0)
        } else {
            DiagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
            result = OdbcUpdateResult(0)
        }

        for (i in 0..params.size) {
            unsafe {
                if (!paramInfo[i].strLenOrInd.isNull()) {
                    free(CPointer<Unit>(paramInfo[i].strLenOrInd))
                }

                if (paramInfo[i].isArrary) {
                    releaseArrayRawData(paramInfo[i].cptrHand)
                } else if (paramInfo[i].isString) {
                    paramInfo[i].string.releaseRaw(paramInfo[i].cptrHand)
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
    public func query(params: Array<SqlDbType>): OdbcQueryResult {
        var ret = unsafe { SQLExecute(STMT_handlePtr) }
        if (SQLSucceeded(ret)) {
            return generateQueryResult(params)
        } else {
            unsafe { DiagnoseException(SQL_HANDLE_STMT, STMT_handlePtr) }
            return unsafe { OdbcQueryResult(STMT_handlePtr, Array<OdbcColumnInfo>()) }
        }
    }

    private func generateUpdateResult(): OdbcUpdateResult {
        var updateResult: OdbcUpdateResult
        var rowCountPtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (rowCountPtr.isNull()) {
            throw SqlException("Native malloc Failed.")
        }
        unsafe { rowCountPtr.write(0) }
        var ret = unsafe { SQLRowCount(STMT_handlePtr, rowCountPtr) }
        if (SQLSucceeded(ret)) {
            if (unsafe { rowCountPtr.read() } > 0) {
                updateResult = OdbcUpdateResult(unsafe { rowCountPtr.read() })
                return updateResult
            } else {
                updateResult = OdbcUpdateResult(0)
            }
        }  else {
            unsafe { DiagnoseException(SQL_HANDLE_STMT, STMT_handlePtr) }
            updateResult = OdbcUpdateResult(0)
        }

        unsafe { free(CPointer<Unit>(rowCountPtr)) }
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
                typeName = "SqlIntger"
            } else {
                typeName = "SqlNullableIntger"
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
        } else {
            throw SqlException("Unknown type ${dataType}, please add type attribute.")
        }

        return typeName
    }

    private func generateQueryResult(params: Array<SqlDbType>): OdbcQueryResult {
        var queryResult: OdbcQueryResult
        var columnCountPtr = CPointer<Int16>(unsafe { malloc(LEN_MALLOC_2) })
        if (columnCountPtr.isNull()) {
            throw SqlException("Native malloc Failed.")
        }

        var ret = unsafe { SQLNumResultCols(STMT_handlePtr, columnCountPtr) }
        if (SQLSucceeded(ret)) {
            var columnCount = unsafe { columnCountPtr.read() }
            if (columnCount > 0) {
                var arrOdbcColumnInfo = Array<OdbcColumnInfo>(Int64(columnCount), item: OdbcColumnInfo())
                for (i in 0..columnCount) {
                    var columnNumber = i + 1
                    var columnNamePtr: CPointer<UInt8>
                    var columnName: CString
                    var bufferLength: Int16 = 1024
                    var nameLengthPtr: CPointer<Int16>
                    var dataTypePtr: CPointer<Int16>
                    var columnSizePtr: CPointer<Int64>
                    var decimalDigitsPtr: CPointer<Int16>
                    var nullablePtr: CPointer<Int16>
                    unsafe {
                        columnNamePtr = CPointer<UInt8>(malloc(1024))
                        columnName = CString(columnNamePtr)
                        nameLengthPtr = CPointer<Int16>(malloc(2))
                        dataTypePtr = CPointer<Int16>(malloc(2))
                        columnSizePtr = CPointer<Int64>(malloc(8))
                        decimalDigitsPtr = CPointer<Int16>(malloc(2))
                        nullablePtr = CPointer<Int16>(malloc(2))
                        ret = SQLDescribeCol(STMT_handlePtr, columnNumber, columnName, bufferLength, nameLengthPtr,
                                             dataTypePtr, columnSizePtr, decimalDigitsPtr, nullablePtr)
                        if (SQLSucceeded(ret)) {
                            var typeName: String
                            var dataType = dataTypePtr.read()
                            var nullable: Int16
                            if (!params.isEmpty()) {
                                typeName = params[Int64(i)].name
                                if (typeName.contains("SqlNullable")) {
                                    nullable = SQL_NULLABLE
                                } else {
                                    nullable = SQL_NO_NULLS
                                }
                            } else {
                                nullable = nullablePtr.read()
                                typeName = getSqlTypeName(dataType, nullable)
                            }
                            var odbcColumnInfo = OdbcColumnInfo(columnName.toString(), typeName, columnSizePtr.read(),
                                                                decimalDigitsPtr.read(), 0, nullable)
                            arrOdbcColumnInfo[Int64(i)] = odbcColumnInfo
                            free(CPointer<Unit>(columnNamePtr))
                            free(CPointer<Unit>(nameLengthPtr))
                            free(CPointer<Unit>(dataTypePtr))
                            free(CPointer<Unit>(columnSizePtr))
                            free(CPointer<Unit>(decimalDigitsPtr))
                            free(CPointer<Unit>(nullablePtr))
                        } else {
                            unsafe { DiagnoseException(SQL_HANDLE_STMT, STMT_handlePtr) }
                        }
                    }
                }
                queryResult = OdbcQueryResult(STMT_handlePtr, arrOdbcColumnInfo)
            } else {
                unsafe { DiagnoseException(SQL_HANDLE_STMT, STMT_handlePtr) }
                queryResult = OdbcQueryResult(STMT_handlePtr, Array<OdbcColumnInfo>())
            }
        }  else {
            unsafe { DiagnoseException(SQL_HANDLE_STMT, STMT_handlePtr) }
            queryResult = OdbcQueryResult(STMT_handlePtr, Array<OdbcColumnInfo>())
        }

        unsafe { free(CPointer<Unit>(columnCountPtr)) }
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
            var cptrHandle = unsafe { realValue.getRaw() }
            var pParameter = unsafe { cptrHandle.pointer }
            var parameterValuePtr = CPointer<Unit>(pParameter)
            unsafe { strLenOrInd.write(Int64(SQL_NTS)) }

            info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
            info.strLenOrInd = strLenOrInd
            info.isString = true
            info.string = realValue
            info.cptrHand = cptrHandle
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
                let realValue: InputStream = v
                var arr = Array<Byte>(realValue.length, item: 0)
                realValue.read(arr)
                var cptrHandle = unsafe { acquireArrayRawData(arr) }
                var parameterValuePtr = cptrHandle.pointer
                unsafe { strLenOrInd.write(Int64(SQL_NTS)) }

                info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
                info.bufferLength = arr.size + 1
                info.strLenOrInd = strLenOrInd
                info.isArrary = true
                info.cptrHand = cptrHandle
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
                let realValue: InputStream = v
                var arr = Array<Byte>(realValue.length, item: 0)
                realValue.read(arr)
                var cptrHandle = unsafe { acquireArrayRawData(arr) }
                var parameterValuePtr = cptrHandle.pointer
                var columnSize = max(arr.size, 1)
                var bufferLength = arr.size
                unsafe { strLenOrInd.write(bufferLength) }

                info.parameterValuePtr = CPointer<Unit>(parameterValuePtr)
                info.bufferLength = columnSize
                info.strLenOrInd = strLenOrInd
                info.isArrary = true
                info.cptrHand = cptrHandle
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

    public func close(): Unit {
        unsafe { SQLFreeHandle(SQL_HANDLE_STMT, this.STMT_handlePtr) }
    }

    public func isClosed(): Bool {
        return unsafe { STMT_handlePtr.isNull() }
    }

    public func getStmtHandle(): CPointer<Unit> {
        unsafe { return this.STMT_handlePtr }
    }
}
