/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
 */

package odbc

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
            var ParameterCountPtr = CPointer<Unit>(unsafe { malloc(2) })
            if (ParameterCountPtr.isNull()) {
                throw SqlException("native malloc Failed.")
            }

            unsafe {
                CPointer<Int16>(ParameterCountPtr).write(0)
                var ret = SQLNumParams(STMT_handlePtr, ParameterCountPtr)
                if (!SQLSucceeded(ret)) {
                    DiagnoseException(SQL_HANDLE_STMT, STMT_handlePtr)
                }

                Int64(CPointer<Int16>(ParameterCountPtr).read())
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
        }
    }


    /**
     * 执行 sql 语句，得到更新结果
     * 返回值 UpdateResult - 更新结果。
     * 异常 SqlException - 执行过程中发生了异常，比如网络中断，服务器超时，参数个数不正确
     */
    public func update(params: Array<SqlDbType>): OdbcUpdateResult {
        var ret: Int16
        for (i in 0..params.size) {
            match (params[i]) {
                case v: SqlChar => setString(i, v.value, SQL_CHAR)
                case v: SqlNullableChar => setString(i, v.value, SQL_CHAR)
                case v: SqlVarchar => setString(i, v.value, SQL_VARCHAR)
                case v: SqlNullableVarchar => setString(i, v.value, SQL_VARCHAR)
                case v: SqlBinary => setBytes(i, v.value, SQL_BINARY)
                case v: SqlNullableBinary => setBytes(i, v.value, SQL_BINARY)
                case v: SqlVarBinary => setBytes(i, v.value, SQL_VARBINARY)
                case v: SqlNullableVarBinary => setBytes(i, v.value, SQL_VARBINARY)
                case v: SqlClob => setClob(i, v.value)
                case v: SqlNullableClob => setClob(i, v.value)
                case v: SqlBlob => setBlob(i, v.value)
                case v: SqlNullableBlob => setBlob(i, v.value)
                case v: SqlBool => setBool(i, v.value)
                case v: SqlNullableBool => setBool(i, v.value)
                case v: SqlByte => setInt8(i, v.value)
                case v: SqlNullableByte => setInt8(i, v.value)
                case v: SqlSmallInt => setInt16(i, v.value)
                case v: SqlNullableSmallInt => setInt16(i, v.value)
                case v: SqlIntger => setInt32(i, v.value)
                case v: SqlNullableIntger => setInt32(i, v.value)
                case v: SqlBigInt => setInt64(i, v.value)
                case v: SqlNullableBigInt => setInt64(i, v.value)
                case v: SqlReal => setFloat32(i, v.value)
                case v: SqlNullableReal => setFloat32(i, v.value)
                case v: SqlDouble => setFloat64(i, v.value)
                case v: SqlNullableDouble => setFloat64(i, v.value)
                case v: SqlDate => setDate(i, v.value)
                case v: SqlNullableDate => setDate(i, v.value)
                case v: SqlTime => setTime(i, v.value)
                case v: SqlNullableTime => setTime(i, v.value)
                case v: SqlTimestampWithoutTz => setTimestampWithoutTz(i, v.value)
                case v: SqlNullableTimestampWithoutTz => setTimestampWithoutTz(i, v.value)
                case _ => throw SqlException("Unsupported data type.")
            }
        }

        ret = unsafe { SQLExecute(STMT_handlePtr) }
        if (SQLSucceeded(ret)) {
            return generateUpdateResult()
        } else if (ret == SQL_NO_DATA) {
            return OdbcUpdateResult(0)
        } else {
            unsafe { DiagnoseException(SQL_HANDLE_STMT, STMT_handlePtr) }
            return OdbcUpdateResult(0)
        }
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
        var rowCountPtr = CPointer<Int64>(unsafe { malloc(8) })
        if (rowCountPtr.isNull()) {
            throw SqlException("native malloc Failed.")
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
        } else if (dataType == SQL_BIT) {
            if (nullable == SQL_NO_NULLS) {
                typeName = "SqlBool"
            } else {
                typeName = "SqlNullableBool"
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
            throw SqlException("Unknown type, please add type attribute.")
        }

        return typeName
    }

    private func generateQueryResult(params: Array<SqlDbType>): OdbcQueryResult {
        var queryResult: OdbcQueryResult
        var columnCountPtr = CPointer<Int16>(unsafe { malloc(2) })
        if (columnCountPtr.isNull()) {
            throw SqlException("native malloc Failed.")
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

    private func setString(index: Int64, value: Option<String>, sqlType: Int16): Unit {
        var ret: Int16
        if (value != None) {
            let realValue: String = value ?? "\0"
            let cstrParameter = unsafe { LibC.mallocCString(realValue) }
            var pParameter = cstrParameter.getChars()
            var pParameterUnit = CPointer<Unit>(pParameter)
            var sqlNTSHandle = CPointer<Int64>(unsafe { malloc(8) })
            var SQL_NTS64: Int64 = -3
            unsafe { sqlNTSHandle.write(SQL_NTS64) }
            ret = unsafe { SQLBindParameter(STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_CHAR,
                                            sqlType,
                                            0,
                                            0,
                                            pParameterUnit,
                                            0,
                                            sqlNTSHandle)
            }
        } else {
            var pParameterUnit = CPointer<Unit>()
            var nullData = CPointer<Int64>(unsafe { malloc(8) })
            if (nullData.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            unsafe { nullData.write(SQL_NULL_DATA) }
            ret = unsafe { SQLBindParameter(STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_CHAR,
                                            sqlType,
                                            STRING_LEN,
                                            0,
                                            pParameterUnit,
                                            0,
                                            nullData)
            }
        }

        if (!SQLSucceeded(ret)) {
            unsafe { DiagnoseException(SQL_HANDLE_STMT, STMT_handlePtr) }
        }
    }

    private func setBytes(index: Int64, value: Option<Array<Byte>>, sqlType: Int16): Unit {
        var ret: Int16
        if (value != None) {
            var parameterValuePtr = CPointer<Byte>(unsafe { malloc(8) })
            let realValue: Array<Byte> = value ?? []
            var cpHandle = unsafe { acquireArrayRawData(realValue) }
            parameterValuePtr = cpHandle.pointer
            var columnSize = UInt64(max(realValue.size, 1))
            var bufferLength = realValue.size
            var nullHandle = CPointer<Int64>()
            ret = unsafe { SQLBindParameter(STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_BINARY,
                                            sqlType,
                                            columnSize,
                                            0,
                                            CPointer<Unit>(parameterValuePtr),
                                            bufferLength,
                                            nullHandle)
            }

            unsafe { releaseArrayRawData(cpHandle) }
        } else {
            var parameterValuePtr = CPointer<Unit>()
            var nullData = CPointer<Int64>(unsafe { malloc(8) })
            if (nullData.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            unsafe { nullData.write(SQL_NULL_DATA) }
            ret = unsafe { SQLBindParameter(this.STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_BINARY,
                                            sqlType,
                                            0,
                                            0,
                                            parameterValuePtr,
                                            0,
                                            nullData)
            }
        }

        if (!SQLSucceeded(ret)) {
            unsafe { DiagnoseException(SQL_HANDLE_STMT, this.STMT_handlePtr) }
        }
    }

    private func setClob(index: Int64, value: Option<InputStream>): Unit {
        var ret: Int16
        match(value) {
            case Some(v) =>
                let realValue: InputStream = v
                var arr = Array<Byte>(realValue.length, item: 0)
                realValue.read(arr)
                var cpHandle = unsafe { acquireArrayRawData(arr) }
                var parameterValuePtr = cpHandle.pointer
                var nullHandle = CPointer<Int64>()
                ret = unsafe { SQLBindParameter(STMT_handlePtr,
                                                index + 1,
                                                SQL_PARAM_INPUT,
                                                SQL_C_CHAR,
                                                SQL_LONGVARCHAR,
                                                0,
                                                0,
                                                CPointer<Unit>(parameterValuePtr),
                                                0,
                                                nullHandle)
                }

                unsafe { releaseArrayRawData(cpHandle) }
            case None =>
                var parameterValuePtr = CPointer<Unit>()
                var nullData = CPointer<Int64>(unsafe { malloc(8) })
                if (nullData.isNull()) {
                    throw SqlException("native malloc Failed.")
                }
                unsafe { nullData.write(SQL_NULL_DATA) }
                ret = unsafe { SQLBindParameter(this.STMT_handlePtr,
                                                index + 1,
                                                SQL_PARAM_INPUT,
                                                SQL_C_CHAR,
                                                SQL_LONGVARCHAR,
                                                0,
                                                0,
                                                parameterValuePtr,
                                                0,
                                                nullData)
                }
        }

        if (!SQLSucceeded(ret)) {
            unsafe { DiagnoseException(SQL_HANDLE_STMT, STMT_handlePtr) }
        }
    }

    private func setBlob(index: Int64, value: Option<InputStream>): Unit {
        var ret: Int16
        match(value) {
            case Some(v) =>
                let realValue: InputStream = v
                var arr = Array<Byte>(realValue.length, item: 0)
                realValue.read(arr)
                var cpHandle = unsafe { acquireArrayRawData(arr) }
                var parameterValuePtr = cpHandle.pointer
                var columnSize = UInt64(max(arr.size, 1))
                var bufferLength = arr.size
                var nullHandle = CPointer<Int64>()
                ret = unsafe { SQLBindParameter(STMT_handlePtr,
                                                index + 1,
                                                SQL_PARAM_INPUT,
                                                SQL_C_BINARY,
                                                SQL_LONGVARBINARY,
                                                columnSize,
                                                0,
                                                CPointer<Unit>(parameterValuePtr),
                                                bufferLength,
                                                nullHandle)
                }

                unsafe { releaseArrayRawData(cpHandle) }
            case None =>
                var parameterValuePtr = CPointer<Unit>()
                var nullData = CPointer<Int64>(unsafe { malloc(8) })
                if (nullData.isNull()) {
                    throw SqlException("native malloc Failed.")
                }
                unsafe { nullData.write(SQL_NULL_DATA) }
                ret = unsafe { SQLBindParameter(STMT_handlePtr,
                                                index + 1,
                                                SQL_PARAM_INPUT,
                                                SQL_C_BINARY,
                                                SQL_LONGVARBINARY,
                                                0,
                                                0,
                                                parameterValuePtr,
                                                0,
                                                nullData)
                }
        }

        if (!SQLSucceeded(ret)) {
            unsafe { DiagnoseException(SQL_HANDLE_STMT, STMT_handlePtr) }
        }
    }

    private func setBool(index: Int64, value: Option<Bool>): Unit {
        var ret: Int16
        if (value != None) {
            var parameterValuePtr = CPointer<Byte>(unsafe { malloc(1) })
            if (parameterValuePtr.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            let realValue: Bool = value.getOrThrow()
            if (realValue) {
                unsafe { parameterValuePtr.write(1) }
            } else {
                unsafe { parameterValuePtr.write(0) }
            }
            var nullHandle = CPointer<Int64>()
            ret = unsafe { SQLBindParameter(STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_BIT,
                                            SQL_BIT,
                                            0,
                                            0,
                                            CPointer<Unit>(parameterValuePtr),
                                            0,
                                            nullHandle)
            }
        } else {
            var parameterValuePtr = CPointer<Unit>()
            var nullData = CPointer<Int64>(unsafe { malloc(8) })
            if (nullData.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            unsafe { nullData.write(SQL_NULL_DATA) }
            ret = unsafe { SQLBindParameter(STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_BIT,
                                            SQL_BIT,
                                            0,
                                            0,
                                            parameterValuePtr,
                                            0,
                                            nullData)
            }
        }

        if (!SQLSucceeded(ret)) {
            unsafe { DiagnoseException(SQL_HANDLE_STMT, STMT_handlePtr) }
        }
    }

    private func setInt8(index: Int64, value: Option<Int8>): Unit {
        var ret: Int16
        if (value != None) {
            var parameterValuePtr = CPointer<Int8>(unsafe { malloc(1) })
            if (parameterValuePtr.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            let realValue: Int8 = value ?? 0
            unsafe { parameterValuePtr.write(realValue) }
            var nullHandle = CPointer<Int64>()
            ret = unsafe { SQLBindParameter(this.STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_STINYINT,
                                            SQL_TINYINT,
                                            0,
                                            0,
                                            CPointer<Unit>(parameterValuePtr),
                                            0,
                                            nullHandle)
            }
        } else {
            var parameterValuePtr = CPointer<Unit>()
            var nullData = CPointer<Int64>(unsafe { malloc(8) })
            if (nullData.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            unsafe { nullData.write(SQL_NULL_DATA) }
            ret = unsafe { SQLBindParameter(this.STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_STINYINT,
                                            SQL_TINYINT,
                                            0,
                                            0,
                                            parameterValuePtr,
                                            0,
                                            nullData)
            }
        }

        if (!SQLSucceeded(ret)) {
            unsafe { DiagnoseException(SQL_HANDLE_STMT, this.STMT_handlePtr) }
        }
    }

    private func setInt16(index: Int64, value: Option<Int16>): Unit {
        var ret: Int16
        if (value != None) {
            var parameterValuePtr = CPointer<Int16>(unsafe { malloc(2) })
            if (parameterValuePtr.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            let realValue: Int16 = value ?? 0
            unsafe { parameterValuePtr.write(realValue) }
            var nullHandle = CPointer<Int64>()
            ret = unsafe { SQLBindParameter(this.STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_SSHORT,
                                            SQL_SMALLINT,
                                            0,
                                            0,
                                            CPointer<Unit>(parameterValuePtr),
                                            0,
                                            nullHandle)
            }
        } else {
            var parameterValuePtr = CPointer<Unit>()
            var nullData = CPointer<Int64>(unsafe { malloc(8) })
            if (nullData.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            unsafe { nullData.write(SQL_NULL_DATA) }
            ret = unsafe { SQLBindParameter(this.STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_SSHORT,
                                            SQL_SMALLINT,
                                            0,
                                            0,
                                            parameterValuePtr,
                                            0,
                                            nullData)
            }
        }

        if (SQLSucceeded(ret)) {
            unsafe { DiagnoseException(SQL_HANDLE_STMT, this.STMT_handlePtr) }
        }
    }

    private func setInt32(index: Int64, value: Option<Int32>): Unit {
        var ret: Int16
        if (value != None) {
            var parameterValuePtr = CPointer<Int32>(unsafe { malloc(4) })
            if (parameterValuePtr.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            let realValue: Int32 = value ?? 0
            unsafe { parameterValuePtr.write(realValue) }
            var nullHandle = CPointer<Int64>()
            ret = unsafe { SQLBindParameter(this.STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_SLONG,
                                            SQL_INTEGER,
                                            0,
                                            0,
                                            CPointer<Unit>(parameterValuePtr),
                                            0,
                                            nullHandle)
            }
        } else {
            var parameterValuePtr = CPointer<Unit>()
            var nullData = CPointer<Int64>(unsafe { malloc(8) })
            if (nullData.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            unsafe { nullData.write(SQL_NULL_DATA) }
            ret = unsafe { SQLBindParameter(this.STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_SLONG,
                                            SQL_INTEGER,
                                            0,
                                            0,
                                            parameterValuePtr,
                                            0,
                                            nullData)
            }
        }

        if (!SQLSucceeded(ret)) {
            unsafe { DiagnoseException(SQL_HANDLE_STMT, this.STMT_handlePtr) }
        }
    }

    private func setInt64(index: Int64, value: Option<Int64>): Unit {
        var ret: Int16
        if (value != None) {
            var parameterValuePtr = CPointer<Int64>(unsafe { malloc(8) })
            if (parameterValuePtr.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            let realValue: Int64 = value ?? 0
            unsafe { parameterValuePtr.write(realValue) }
            var nullHandle = CPointer<Int64>()
            ret = unsafe { SQLBindParameter(this.STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_SBIGINT,
                                            SQL_BIGINT,
                                            0,
                                            0,
                                            CPointer<Unit>(parameterValuePtr),
                                            0,
                                            nullHandle)
            }
        } else {
            var parameterValuePtr = CPointer<Unit>()
            var nullData = CPointer<Int64>(unsafe { malloc(8) })
            if (nullData.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            unsafe { nullData.write(SQL_NULL_DATA) }
            ret = unsafe { SQLBindParameter(this.STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_SBIGINT,
                                            SQL_BIGINT,
                                            0,
                                            0,
                                            parameterValuePtr,
                                            0,
                                            nullData)
            }
        }
        if (!SQLSucceeded(ret)) {
            unsafe { DiagnoseException(SQL_HANDLE_STMT, this.STMT_handlePtr) }
        }
    }

    private func setFloat32(index: Int64, value: Option<Float32>): Unit {
        var ret: Int16
        if (value != None) {
            var parameterValuePtr = CPointer<Float32>(unsafe { malloc(4) })
            if (parameterValuePtr.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            let realValue: Float32 = value ?? 0.0
            unsafe { parameterValuePtr.write(realValue) }
            var nullHandle = CPointer<Int64>()
            ret = unsafe { SQLBindParameter(this.STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_FLOAT,
                                            SQL_REAL,
                                            7,
                                            0,
                                            CPointer<Unit>(parameterValuePtr),
                                            0,
                                            nullHandle)
            }
        } else {
            var parameterValuePtr = CPointer<Unit>()
            var nullData = CPointer<Int64>(unsafe { malloc(8) })
            if (nullData.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            unsafe { nullData.write(SQL_NULL_DATA) }
            ret = unsafe { SQLBindParameter(this.STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_FLOAT,
                                            SQL_REAL,
                                            7,
                                            0,
                                            parameterValuePtr,
                                            0,
                                            nullData)
            }
        }

        if (!SQLSucceeded(ret)) {
            unsafe { DiagnoseException(SQL_HANDLE_STMT, this.STMT_handlePtr) }
        }
    }

    private func setFloat64(index: Int64, value: Option<Float64>): Unit {
        var ret: Int16
        if (value != None) {
            var parameterValuePtr = CPointer<Float64>(unsafe { malloc(8) })
            if (parameterValuePtr.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            let realValue: Float64 = value ?? 0.0
            unsafe { parameterValuePtr.write(realValue) }
            var nullHandle = CPointer<Int64>(unsafe { malloc(8) })
            unsafe {nullHandle.write(15)}
            ret = unsafe { SQLBindParameter(this.STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_DOUBLE,
                                            SQL_DOUBLE,
                                            15,
                                            0,
                                            CPointer<Unit>(parameterValuePtr),
                                            0,
                                            nullHandle)
            }
        } else {
            var parameterValuePtr = CPointer<Unit>()
            var nullData = CPointer<Int64>(unsafe { malloc(8) })
            if (nullData.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            unsafe { nullData.write(SQL_NULL_DATA) }
            ret = unsafe { SQLBindParameter(this.STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_DOUBLE,
                                            SQL_DOUBLE,
                                            15,
                                            0,
                                            parameterValuePtr,
                                            0,
                                            nullData)
            }
        }

        if (!SQLSucceeded(ret)) {
            unsafe { DiagnoseException(SQL_HANDLE_STMT, this.STMT_handlePtr) }
        }
    }

    private func setDate(index: Int64, value: Option<DateTime>): Unit {
        var ret: Int16
        if (value != None) {
            var parameterValuePtr = CPointer<DATE_STRUCT>(unsafe { malloc(6) })
            if (parameterValuePtr.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            let realValue: DateTime = value.getOrThrow()
            var date = DATE_STRUCT()
            date.year = Int16(realValue.year)
            date.month = Int16(realValue.monthValue)
            date.day = Int16(realValue.dayOfMonth)

            unsafe { parameterValuePtr.write(date) }
            var columnSize = 16
            var nullHandle = CPointer<Int64>()
            ret = unsafe { SQLBindParameter(this.STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_TYPE_DATE,
                                            SQL_TYPE_DATE,
                                            UInt64(columnSize),
                                            0,
                                            CPointer<Unit>(parameterValuePtr),
                                            6,
                                            nullHandle)
            }
        } else {
            var parameterValuePtr = CPointer<Unit>()
            var nullData = CPointer<Int64>(unsafe { malloc(8) })
            if (nullData.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            unsafe { nullData.write(SQL_NULL_DATA) }
            ret = unsafe { SQLBindParameter(this.STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_TYPE_DATE,
                                            SQL_TYPE_DATE,
                                            0,
                                            0,
                                            parameterValuePtr,
                                            0,
                                            nullData)
            }
        }

        if (!SQLSucceeded(ret)) {
            unsafe { DiagnoseException(SQL_HANDLE_STMT, this.STMT_handlePtr) }
        }
    }

    private func setTime(index: Int64, value: Option<DateTime>): Unit {
        var ret: Int16
        if (value != None) {
            var parameterValuePtr = CPointer<TIME_STRUCT>(unsafe { malloc(6) })
            if (parameterValuePtr.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            let realValue: DateTime = value.getOrThrow()
            var time = TIME_STRUCT()
            time.hour = Int16(realValue.hour)
            time.minute = Int16(realValue.minute)
            time.second = Int16(realValue.second)

            unsafe { parameterValuePtr.write(time) }
            var columnSize = 16
            var nullHandle = CPointer<Int64>()
            ret = unsafe { SQLBindParameter(this.STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_TYPE_TIME,
                                            SQL_TYPE_TIME,
                                            UInt64(columnSize),
                                            0,
                                            CPointer<Unit>(parameterValuePtr),
                                            6,
                                            nullHandle)
            }
        } else {
            var parameterValuePtr = CPointer<Unit>()
            var nullData = CPointer<Int64>(unsafe { malloc(8) })
            if (nullData.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            unsafe { nullData.write(SQL_NULL_DATA) }
            ret = unsafe { SQLBindParameter(this.STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_TYPE_TIME,
                                            SQL_TYPE_TIME,
                                            0,
                                            0,
                                            parameterValuePtr,
                                            0,
                                            nullData)
            }
        }

        if (!SQLSucceeded(ret)) {
            unsafe { DiagnoseException(SQL_HANDLE_STMT, this.STMT_handlePtr) }
        }
    }

    private func setTimestampWithoutTz(index: Int64, value: Option<DateTime>): Unit {
        var ret: Int16
        if (value != None) {
            var parameterValuePtr = CPointer<TIMESTAMP_STRUCT>(unsafe { malloc(16) })
            if (parameterValuePtr.isNull()) {
                throw SqlException("native malloc Failed.")
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
            var columnSize = 16
            var nullHandle = CPointer<Int64>()
            ret = unsafe { SQLBindParameter(this.STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_TYPE_TIMESTAMP,
                                            SQL_TYPE_TIMESTAMP,
                                            UInt64(columnSize),
                                            0,
                                            CPointer<Unit>(parameterValuePtr),
                                            16,
                                            nullHandle)
            }
        } else {
            var parameterValuePtr = CPointer<Unit>()
            var nullData = CPointer<Int64>(unsafe { malloc(8) })
            if (nullData.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            unsafe { nullData.write(SQL_NULL_DATA) }
            ret = unsafe { SQLBindParameter(this.STMT_handlePtr,
                                            index + 1,
                                            SQL_PARAM_INPUT,
                                            SQL_C_TYPE_TIMESTAMP,
                                            SQL_TYPE_TIMESTAMP,
                                            0,
                                            0,
                                            parameterValuePtr,
                                            0,
                                            nullData)
            }
        }

        if (!SQLSucceeded(ret)) {
            unsafe { DiagnoseException(SQL_HANDLE_STMT, this.STMT_handlePtr) }
        }
    }

    public func close(): Unit {
        unsafe { SQLFreeHandle(SQL_HANDLE_STMT, this.STMT_handlePtr) }
    }

    public func isClosed(): Bool {
        return unsafe { this.STMT_handlePtr.isNull() }
    }

    public func getStmtHandle(): CPointer<Unit> {
        unsafe { return this.STMT_handlePtr }
    }
}
