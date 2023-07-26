/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
 */

package odbc

/* 执行 Select 语句产生的结果接口 */
public class OdbcQueryResult <: QueryResult {
    private var resultCount: Array<OdbcColumnInfo>
    private var STMT_handle: CPointer<Unit>

    public init(STMT_handle: CPointer<Unit>, resultCount: Array<OdbcColumnInfo>) {
        this.STMT_handle = STMT_handle
        this.resultCount = resultCount
    }

    /**
     * 返回结果集的列信息，比如列名，列类型，列长度，是否允许数据库 Null 值等
     */
    public prop columnInfos: Array<ColumnInfo> {
        get() {
            Array<ColumnInfo>(resultCount.size, {i => (resultCount[i] as OdbcColumnInfo).getOrThrow()})
        }
    }

    public func getSqlDbType(): Array<SqlDbType> {
        var arr: Array<SqlDbType> = Array<SqlDbType>(columnInfos.size, item: SqlChar(""))
        for (i in 0..columnInfos.size) {
            if (columnInfos[i].typeName == "SqlChar") {
                arr.set(i, SqlChar(""))
            } else if (columnInfos[i].typeName == "SqlNullableChar") {
                arr.set(i, SqlNullableChar(""))
            } else if (columnInfos[i].typeName == "SqlVarchar") {
                arr.set(i, SqlVarchar(""))
            } else if (columnInfos[i].typeName == "SqlNullableVarchar") {
                arr.set(i, SqlNullableVarchar(""))
            } else if (columnInfos[i].typeName == "SqlBinary") {
                arr.set(i, SqlBinary(Array<Byte>()))
            } else if (columnInfos[i].typeName == "SqlNullableBinary") {
                arr.set(i, SqlNullableBinary(Array<Byte>()))
            } else if (columnInfos[i].typeName == "SqlVarBinary") {
                arr.set(i, SqlVarBinary(Array<Byte>()))
            } else if (columnInfos[i].typeName == "SqlNullableVarBinary") {
                arr.set(i, SqlNullableVarBinary(Array<Byte>()))
            } else if (columnInfos[i].typeName == "SqlClob") {
                arr.set(i, SqlClob(ByteArrayStream(0)))
            } else if (columnInfos[i].typeName == "SqlNullableClob") {
                arr.set(i, SqlNullableClob(ByteArrayStream(0)))
            } else if (columnInfos[i].typeName == "SqlBlob") {
                arr.set(i, SqlBlob(ByteArrayStream(0)))
            } else if (columnInfos[i].typeName == "SqlNullableBlob") {
                arr.set(i, SqlNullableBlob(ByteArrayStream(0)))
            } else if (columnInfos[i].typeName == "SqlBool") {
                arr.set(i, SqlBool(true))
            } else if (columnInfos[i].typeName == "SqlNullableBool") {
                arr.set(i, SqlNullableBool(true))
            } else if (columnInfos[i].typeName == "SqlByte") {
                arr.set(i, SqlByte(0))
            } else if (columnInfos[i].typeName == "SqlNullableByte") {
                arr.set(i, SqlNullableByte(0))
            } else if (columnInfos[i].typeName == "SqlSmallInt") {
                arr.set(i, SqlSmallInt(0))
            } else if (columnInfos[i].typeName == "SqlNullableSmallInt") {
                arr.set(i, SqlNullableSmallInt(0))
            } else if (columnInfos[i].typeName == "SqlIntger") {
                arr.set(i, SqlIntger(0))
            } else if (columnInfos[i].typeName == "SqlNullableIntger") {
                arr.set(i, SqlNullableIntger(0))
            } else if (columnInfos[i].typeName == "SqlBigInt") {
                arr.set(i, SqlBigInt(0))
            } else if (columnInfos[i].typeName == "SqlNullableBigInt") {
                arr.set(i, SqlNullableBigInt(0))
            } else if (columnInfos[i].typeName == "SqlReal") {
                arr.set(i, SqlReal(0.0))
            } else if (columnInfos[i].typeName == "SqlNullableReal") {
                arr.set(i, SqlNullableReal(0.0))
            } else if (columnInfos[i].typeName == "SqlDouble") {
                arr.set(i, SqlDouble(0.0))
            } else if (columnInfos[i].typeName == "SqlNullableDouble") {
                arr.set(i, SqlNullableDouble(0.0))
            } else if (columnInfos[i].typeName == "SqlDate") {
                arr.set(i, SqlDate(DateTime.now()))
            } else if (columnInfos[i].typeName == "SqlNullableDate") {
                arr.set(i, SqlNullableDate(DateTime.now()))
            } else if (columnInfos[i].typeName == "SqlTime") {
                arr.set(i, SqlTime(DateTime.now()))
            } else if (columnInfos[i].typeName == "SqlNullableTime") {
                arr.set(i, SqlNullableTime(DateTime.now()))
            } else if (columnInfos[i].typeName == "SqlTimestampWithoutTz") {
                arr.set(i, SqlTimestampWithoutTz(DateTime.now()))
            } else if (columnInfos[i].typeName == "SqlNullableTimestampWithoutTz") {
                arr.set(i, SqlNullableTimestampWithoutTz(DateTime.now()))
            } else {
                throw SqlException("Unknown sql type.")
            }
        }

        arr
    }

    /**
     * 向后移动一行，必须先调用一次 next 才能移动到第一行，第二次调用移动到第二行，依此类推。
     * 当返回 true 时，驱动会在 values 中填入行数据；当返回 false 时结束，且不会修改 values 的内容。
     * 返回值 Bool - 存在下一行则返回 true，否则返回 false
     */
    public func next(values: Array<SqlDbType>): Bool {
        var res = unsafe { SQLFetch(STMT_handle) }
        if (res == SQL_NO_DATA) {
            return false
        } else {
            for (i in 0..values.size) {
                match (values[i]) {
                    case v: SqlChar => v.value = getString(i) ?? ""
                    case v: SqlNullableChar => v.value = getString(i)
                    case v: SqlVarchar => v.value = getString(i) ?? ""
                    case v: SqlNullableVarchar => v.value = getString(i)
                    case v: SqlBinary => v.value = getBytes(i) ?? Array<Byte>()
                    case v: SqlNullableBinary => v.value = getBytes(i)
                    case v: SqlVarBinary => v.value = getBytes(i) ?? Array<Byte>()
                    case v: SqlNullableVarBinary => v.value = getBytes(i)
                    case v: SqlClob => v.value = getClob(i).getOrThrow()
                    case v: SqlNullableClob => v.value = getClob(i)
                    case v: SqlBlob => v.value = getBlob(i).getOrThrow()
                    case v: SqlNullableBlob => v.value = getBlob(i)
                    case v: SqlBool => v.value = getBool(i).getOrThrow()
                    case v: SqlNullableBool => v.value = getBool(i)
                    case v: SqlByte => v.value = getInt8(i).getOrThrow()
                    case v: SqlNullableByte => v.value = getInt8(i)
                    case v: SqlSmallInt => v.value = getInt16(i).getOrThrow()
                    case v: SqlNullableSmallInt => v.value = getInt16(i)
                    case v: SqlIntger => v.value = getInt32(i).getOrThrow()
                    case v: SqlNullableIntger => v.value = getInt32(i)
                    case v: SqlBigInt => v.value = getInt64(i).getOrThrow()
                    case v: SqlNullableBigInt => v.value = getInt64(i)
                    case v: SqlReal => v.value = getFloat32(i).getOrThrow()
                    case v: SqlNullableReal => v.value = getFloat32(i)
                    case v: SqlDouble => v.value = getFloat64(i).getOrThrow()
                    case v: SqlNullableDouble => v.value = getFloat64(i)
                    case v: SqlDate => v.value = getDate(i).getOrThrow()
                    case v: SqlNullableDate => v.value = getDate(i)
                    case v: SqlTime => v.value = getTime(i).getOrThrow()
                    case v: SqlNullableTime => v.value = getTime(i)
                    case v: SqlTimestampWithoutTz => v.value = getTimestampWithoutTz(i).getOrThrow()
                    case v: SqlNullableTimestampWithoutTz => v.value = getTimestampWithoutTz(i)
                    case _ => ()
                }
            }
        }
        return true
    }

    private func readVarColumn(index: Int64, ctype: Int16): DataBuffer {
        let cbNullTerminator = 0

        var cbAllocated = 4096
        var cbUsed = 0
        var pb = CPointer<Unit>(unsafe { malloc(UIntNative(cbAllocated)) })
        if (pb.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var cbData = CPointer<Int64>(unsafe { malloc(8) })
        if (cbData.isNull()) {
            unsafe { free(pb) }
            throw SqlException("Native malloc failed.")
        }
        var ret = SQL_SUCCESS_WITH_INFO

        do {
            var cbAvailable = cbAllocated - cbUsed
            unsafe { cbData.write(0) }
            ret = unsafe { SQLGetData(this.STMT_handle, index + 1, ctype, pb, cbAllocated, cbData) }

            if (!SQLSucceeded(ret) && ret != SQL_NO_DATA) {
                DiagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
                unsafe {
                    free(pb)
                    free(CPointer<Unit>(cbData))
                }
                return DataBuffer()
            }

            var data = unsafe { cbData.read() }
            if (ret == SQL_SUCCESS && data < 0) {
                ret = Int16(SQL_NULL_DATA)
                unsafe { cbData.write(0) }
            }

            if (ret == SQL_SUCCESS_WITH_INFO) {
                var cbRemaining = 0
                var cbRead = 0
                if (data == SQL_NO_TOTAL) {
                    cbRead = cbAvailable - cbNullTerminator
                    cbRemaining = 1024 * 1024
                } else if (data >= cbAvailable) {
                    cbRead = cbAvailable - cbNullTerminator
                    cbRemaining = data - cbRead
                } else {
                    cbRead = data - cbNullTerminator
                    cbRemaining = 0
                }

                cbUsed += cbRead

                if (cbRemaining > 0) {
                    var cbNeed = cbUsed + cbRemaining + cbNullTerminator
                    var ptr = unsafe { realloc(pb, cbNeed) }
                    if (ptr.isNull()) {
                        unsafe {
                            free(CPointer<Unit>(pb))
                            free(CPointer<Unit>(cbData))
                        }
                        throw SqlException("Native realloc failed.")
                    }
                    pb = ptr
                    cbAllocated = cbNeed
                }
            } else if (ret == SQL_SUCCESS) {
                cbUsed += data
            }

        } while(ret == SQL_SUCCESS_WITH_INFO)

        if (ret != Int16(SQL_NULL_DATA) && cbUsed > 0) {
            var buffer = DataBuffer()
            buffer.data = pb
            buffer.len = cbUsed
            unsafe { free(CPointer<Unit>(cbData)) }
            return buffer
        } else {
            unsafe {
                free(pb)
                free(CPointer<Unit>(cbData))
            }
            return DataBuffer()
        }
    }

    private func getString(index: Int64): Option<String> {
        var buffer = readVarColumn(index, SQL_C_CHAR)
        if (buffer.data.isNull()) {
            return None
        } else {
            var colValue = CString(CPointer<UInt8>(buffer.data))
            var ret = Some(colValue.toString())
            unsafe { free(buffer.data) }
            return ret
        }
    }

    private func getBytes(index: Int64): Option<Array<Byte>> {
        var buffer = readVarColumn(index, SQL_C_BINARY)
        if (buffer.data.isNull()) {
            return None
        } else {
            var colValuePtr = CPointer<Byte>(buffer.data)
            var arr = Array<Byte>(buffer.len, item: 0)
            for (i in 0..buffer.len) {
                arr[i] = unsafe { colValuePtr.read(i) }
            }
            unsafe { free(buffer.data) }
            return Some(arr)
        }
    }

    private func getClob(index: Int64): Option<InputStream> {
        var buffer = readVarColumn(index, SQL_C_CHAR)
        if (buffer.data.isNull()) {
            return None
        } else {
            var colValuePtr = CPointer<Byte>(buffer.data)
            var arr = Array<Byte>(buffer.len, item: 0)
            for (i in 0..buffer.len) {
                arr[i] = unsafe { colValuePtr.read(i) }
            }

            unsafe { free(buffer.data) }
            var stream = ByteArrayStream()
            stream.write(arr)
            return Some(stream)
        }
    }

    private func getBlob(index: Int64): Option<InputStream> {
        var buffer = readVarColumn(index, SQL_C_BINARY)
        if (buffer.data.isNull()) {
            return None
        } else {
            var colValuePtr = CPointer<Byte>(buffer.data)
            var arr = Array<Byte>(buffer.len, item: 0)
            for (i in 0..buffer.len) {
                arr[i] = unsafe { colValuePtr.read(i) }
            }

            unsafe { free(buffer.data) }
            var stream = ByteArrayStream()
            stream.write(arr)
            return Some(stream)
        }
    }

    private func getBool(index: Int64): Option<Bool> {
        let colValueSize = 1
        var res: Option<Bool> = None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(1) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(8) })
        if (sizePtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_BIT, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            DiagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw SqlException("Get Bool data failed.")
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<UInt8>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }

            if (colValue == 1) {
                res = Some(true)
            } else {
                res = Some(false)
            }
        }

        unsafe {
            free(colValueUnitPtr)
            free(CPointer<Unit>(sizePtr))
        }
        return res
    }

    private func getInt8(index: Int64): Option<Int8> {
        let colValueSize = 1
        var res: Option<Int8> = None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(1) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(8) })
        if (sizePtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_STINYINT, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            DiagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw SqlException("Get Int8 data failed.")
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<Int8>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            res = Some(colValue)
        }

        unsafe {
            free(colValueUnitPtr)
            free(CPointer<Unit>(sizePtr))
        }
        return res
    }

    private func getInt16(index: Int64): Option<Int16> {
        let colValueSize = 2
        var res: Option<Int16> = None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(2) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(8) })
        if (sizePtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_SSHORT, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            unsafe { DiagnoseException(SQL_HANDLE_STMT, this.STMT_handle) }
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw SqlException("Get Int16 data failed.")
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<Int16>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            res = Some(colValue)
        }

        unsafe {
            free(colValueUnitPtr)
            free(CPointer<Unit>(sizePtr))
        }
        return res
    }

    private func getInt32(index: Int64): Option<Int32> {
        let colValueSize = 4
        var res: Option<Int32> = None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(4) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(8) })
        if (sizePtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_SLONG, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            DiagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw SqlException("Get Int32 data failed.")
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<Int32>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            res = Some(colValue)
        }

        unsafe {
            free(colValueUnitPtr)
            free(CPointer<Unit>(sizePtr))
        }
        return res
    }

    private func getInt64(index: Int64): Option<Int64> {
        let colValueSize = 8
        var res: Option<Int64> = None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(8) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(8) })
        if (sizePtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_SBIGINT, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            DiagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw SqlException("Get Int64 data failed.")
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<Int64>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            res = Some(colValue)
        }

        unsafe {
            free(colValueUnitPtr)
            free(CPointer<Unit>(sizePtr))
        }
        return res
    }

    private func getFloat32(index: Int64): Option<Float32> {
        let colValueSize = 4
        var res: Option<Float32> = None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(4) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(8) })
        if (sizePtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_FLOAT, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            DiagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw SqlException("Get Float32 data failed.")
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<Float32>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            res = Some(colValue)
        }

        unsafe {
            free(colValueUnitPtr)
            free(CPointer<Unit>(sizePtr))
        }
        return res
    }

    private func getFloat64(index: Int64): Option<Float64> {
        let colValueSize = 8
        var res: Option<Float64> = None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(8) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(8) })
        if (sizePtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_DOUBLE, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            DiagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw SqlException("Get Float64 data failed.")
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<Float64>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            res = Some(colValue)
        }

        unsafe {
            free(colValueUnitPtr)
            free(CPointer<Unit>(sizePtr))
        }
        return res
    }

    private func getDate(index: Int64): Option<DateTime> {
        let colValueSize = 16
        var res = Option<DateTime>.None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(6) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(8) })
        if (sizePtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_TYPE_DATE, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            DiagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw SqlException("Get date failed.")
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<DATE_STRUCT>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            var timestamp = DateTime.of(
                year: Int64(colValue.year),
                month: Int64(colValue.month),
                dayOfMonth: Int64(colValue.day),
                hour: 0,
                minute: 0,
                second: 0,
                nanosecond: 0,
            )
            res = Some(timestamp)
        }

        unsafe {
            free(colValueUnitPtr)
            free(CPointer<Unit>(sizePtr))
        }
        return res
    }

    private func getTime(index: Int64): Option<DateTime> {
        let colValueSize = 16
        var res = Option<DateTime>.None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(6) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(8) })
        if (sizePtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_TYPE_TIME, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            DiagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw SqlException("Get time failed.")
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<TIME_STRUCT>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            var timestamp = DateTime.of(
                year: 1970,
                month: 1,
                dayOfMonth: 1,
                hour: Int64(colValue.hour),
                minute: Int64(colValue.minute),
                second: Int64(colValue.second),
                nanosecond: 0,
            )
            res = Some(timestamp)
        }

        unsafe {
            free(colValueUnitPtr)
            free(CPointer<Unit>(sizePtr))
        }
        return res
    }



    private func getTimestampWithoutTz(index: Int64): Option<DateTime> {
        let colValueSize = 16
        var res = Option<DateTime>.None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(16) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(8) })
        if (sizePtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_TYPE_TIMESTAMP, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            DiagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw SqlException("Get timestamp failed.")
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<TIMESTAMP_STRUCT>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            var timestamp = DateTime.of(
                year: Int64(colValue.year),
                month: Int64(colValue.month),
                dayOfMonth: Int64(colValue.day),
                hour: Int64(colValue.hour),
                minute: Int64(colValue.minute),
                second: Int64(colValue.second),
                nanosecond: Int64(colValue.fraction),
            )
            res = Some(timestamp)
        }

        unsafe {
            free(colValueUnitPtr)
            free(CPointer<Unit>(sizePtr))
        }
        return res
    }

    public func close(): Unit {
        println("Result is closed")
    }

    public func isClosed(): Bool {
        return false
    }
}
