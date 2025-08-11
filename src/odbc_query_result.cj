/*
 * @Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights reserved.
 */

package odbc4cj

/* 执行 Select 语句产生的结果接口 */
public class OdbcQueryResult <: QueryResult {
    private var resultCount: Array<OdbcColumnInfo>
    private var STMT_handle: CPointer<Unit>
    private let closed = AtomicBool(false)
    private var resultSet: Array<Any>

    init(STMT_handle: CPointer<Unit>, resultCount: Array<OdbcColumnInfo>) {
        this.STMT_handle = STMT_handle
        this.resultCount = resultCount
        this.resultSet = Array<Any>(resultCount.size, repeat: Option<Any>.None)
    }

    /**
     * 返回结果集的列信息，比如列名，列类型，列长度，是否允许数据库 Null 值等
     */
    public override prop columnInfos: Array<ColumnInfo> {
        get() {
            Array<ColumnInfo>(resultCount.size, {i => (resultCount[i] as OdbcColumnInfo).getOrThrow()})
        }
    }

    /*
     * 向后移动一行，必须先调用一次 next() 才能移动到第一行，第二次调用移动到第二行，依此类推。当返回 true 时，驱动会在结果集的当前行填入数据，当返回 false 时结束，且不会修改结果集当前行的内容。
     *
     * 返回值 Bool - 存在下一行则返回true，否则返回false
     * 异常 Exception - 传入参数错误
     */
    public override func next(): Bool {
        if (STMT_handle.isNull()) {
            throw SqlException("Native malloc Failed.")
        }
        var res = unsafe { SQLFetch(STMT_handle) }
        if (res == SQL_NO_DATA) {
            return false
        } else {
            for (i in 0..resultCount.size) {
                match (resultCount[i].typeName) {
                    case "SqlString" => resultSet[i] = getString(i)
                    case "SqlArrayByte" => resultSet[i] = getBytes(i)
                    case "SqlInputStream" => resultSet[i] = getBlob(i)
                    case "SqlClob" => resultSet[i] = getClob(i)
                    case "SqlBool" => resultSet[i] = getBool(i)
                    case "SqlInt8" => resultSet[i] = getInt8(i)
                    case "SqlInt16" => resultSet[i] = getInt16(i)
                    case "SqlInt32" => resultSet[i] = getInt32(i)
                    case "SqlInt64" => resultSet[i] = getInt64(i)
                    case "SqlFloat32" => resultSet[i] = getFloat32(i)
                    case "SqlFloat64" => resultSet[i] = getFloat64(i)
                    case "SqlOdbcTypeDate" => resultSet[i] = getDate(i)
                    case "SqlOdbcTypeTime" => resultSet[i] = getTime(i)
                    case "SqlOdbcTypeTimeTimestamp" => resultSet[i] = getTimestampWithoutTz(i)
                    case "SqlDecimal" => resultSet[i] = getDecimal(i)
                    case _ => throw SqlException("Unsupported data type.")
                }
            }
        }
        return true
    }

    /*
     * 获取数据
     *
     * 参数 index - 位置
     * 返回值 T - 值
     * 异常 Exception - 传入参数错误
     */
    public override func get<T>(index: Int): T {
        return getOrNull<T>(index) ?? throw NoneValueException()
    }

    /*
     * 获取可以为null的数据
     *
     * 参数 index - 位置
     * 返回值 ?T - 值
     * 异常 Exception - 传入参数错误
     */
    public override func getOrNull<T>(index: Int): ?T {
        checkResource()
        if (index < 0) {
            throw IllegalArgumentException("Index must be greater than or equal to 0")
        }
        return (resultSet[index] as ?T) ?? throw IllegalStateException()
    }

    /**
     * 向后移动一行，必须先调用一次 next 才能移动到第一行，第二次调用移动到第二行，依此类推。
     * 当返回 true 时，驱动会在 values 中填入行数据；当返回 false 时结束，且不会修改 values 的内容。
     * 返回值 Bool - 存在下一行则返回 true，否则返回 false
     */
    @Deprecated
    public override func next(values: Array<SqlDbType>): Bool {
        if (values.size <= 0) {
            throw SqlException("Data query failed")
        }
        if (STMT_handle.isNull()) {
            throw SqlException("Native malloc Failed.")
        }
        var res = unsafe { SQLFetch(STMT_handle) }
        if (res == SQL_NO_DATA) {
            return false
        } else {
            for (i in 0..values.size) {
                match (values[i]) {
                    case v: SqlChar => v.value = getOldString(i) ?? ""
                    case v: SqlNullableChar => v.value = getOldString(i)
                    case v: SqlVarchar => v.value = getOldString(i) ?? ""
                    case v: SqlNullableVarchar => v.value = getOldString(i)
                    case v: SqlBinary => v.value = getOldBytes(i) ?? Array<Byte>()
                    case v: SqlNullableBinary => v.value = getOldBytes(i)
                    case v: SqlVarBinary => v.value = getOldBytes(i) ?? Array<Byte>()
                    case v: SqlNullableVarBinary => v.value = getOldBytes(i)
                    case v: SqlClob => v.value = getOldClob(i).getOrThrow()
                    case v: SqlNullableClob => v.value = getOldClob(i)
                    case v: SqlBlob => v.value = getOldBlob(i).getOrThrow()
                    case v: SqlNullableBlob => v.value = getOldBlob(i)
                    case v: SqlBool => v.value = getOldBool(i).getOrThrow()
                    case v: SqlNullableBool => v.value = getOldBool(i)
                    case v: SqlByte => v.value = getOldInt8(i).getOrThrow()
                    case v: SqlNullableByte => v.value = getOldInt8(i)
                    case v: SqlSmallInt => v.value = getOldInt16(i).getOrThrow()
                    case v: SqlNullableSmallInt => v.value = getOldInt16(i)
                    case v: SqlInteger => v.value = getOldInt32(i).getOrThrow()
                    case v: SqlNullableInteger => v.value = getOldInt32(i)
                    case v: SqlBigInt => v.value = getOldInt64(i).getOrThrow()
                    case v: SqlNullableBigInt => v.value = getOldInt64(i)
                    case v: SqlReal => v.value = getOldFloat32(i).getOrThrow()
                    case v: SqlNullableReal => v.value = getOldFloat32(i)
                    case v: SqlDouble => v.value = getOldFloat64(i).getOrThrow()
                    case v: SqlNullableDouble => v.value = getFloat64(i)
                    case v: SqlDate => v.value = getOldDate(i).getOrThrow()
                    case v: SqlNullableDate => v.value = getOldDate(i)
                    case v: SqlTime => v.value = getOldTime(i).getOrThrow()
                    case v: SqlNullableTime => v.value = getOldTime(i)
                    case v: SqlTimestampWithoutTz => v.value = getOldTimestampWithoutTz(i).getOrThrow()
                    case v: SqlNullableTimestampWithoutTz => v.value = getOldTimestampWithoutTz(i)
                    case v: SqlDecimal => v.value = getOldDecimal(i).getOrThrow()
                    case v: SqlNullableDecimal => v.value = getOldDecimal(i)
                    case _ => throw SqlException("Unsupported data type.")
                }
            }
        }
        return true
    }

    private func readVarColumn(index: Int64, ctype: Int16): DataBuffer {
        var cbNullTerminator = 1
        if (ctype == SQL_BINARY || ctype == SQL_VARBINARY || ctype == SQL_LONGVARBINARY) {
            cbNullTerminator = 0
        }

        var cbAllocated = resultCount[index].displaySize
        var cbUsed = 0
        var pb: CPointer<Unit> = CPointer<Unit>(LibC.malloc<Int8>(count: cbAllocated))
        if (pb.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var cbData = LibC.malloc<Int64>()
        if (cbData.isNull()) {
            unsafe { LibC.free(pb) }
            throw SqlException("Native malloc failed.")
        }
        var ret = SQL_SUCCESS_WITH_INFO

        var isNull = false

        do {
            var cbAvailable = cbAllocated - cbUsed
            unsafe { cbData.write(0) }
            ret = unsafe { SQLGetData(this.STMT_handle, index + 1, ctype, pb + cbUsed, cbAllocated, cbData) }

            if (!SQLSucceeded(ret) && ret != SQL_NO_DATA) {
                diagnoseException(SQL_HANDLE_STMT, STMT_handle)
                unsafe {
                    LibC.free(pb)
                    LibC.free(cbData)
                }
                return DataBuffer()
            }

            var data = unsafe { cbData.read() }
            if (ret == SQL_SUCCESS && data < 0) {
                ret = Int16(SQL_NULL_DATA)
                unsafe { cbData.write(0) }
                isNull = true
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
                            LibC.free(pb)
                            LibC.free(cbData)
                        }
                        throw SqlException("Native realloc failed.")
                    }
                    pb = ptr
                    cbAllocated = cbNeed
                }
            } else if (ret == SQL_SUCCESS) {
                cbUsed += data
            }
        } while (ret == SQL_SUCCESS_WITH_INFO)

        if (ret != Int16(SQL_NULL_DATA) && cbUsed > 0) {
            var buffer = DataBuffer()
            buffer.data = pb
            buffer.len = cbUsed
            unsafe { LibC.free(cbData) }
            return buffer
        } else {
            if (!isNull) {
                var buffer = DataBuffer()
                buffer.data = pb
                buffer.len = cbUsed
                unsafe { LibC.free(cbData) }
                return buffer
            }
            unsafe {
                LibC.free(pb)
                LibC.free(cbData)
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
            unsafe { LibC.free(buffer.data) }
            return ret
        }
    }

    private func getBytes(index: Int64): Option<Array<Byte>> {
        var buffer = readVarColumn(index, SQL_C_BINARY)
        if (buffer.data.isNull()) {
            return None
        } else {
            var colValuePtr = CPointer<Byte>(buffer.data)
            var arr = Array<Byte>(buffer.len, repeat: 0)
            for (i in 0..buffer.len) {
                arr[i] = unsafe { colValuePtr.read(i) }
            }
            unsafe { LibC.free(buffer.data) }
            return Some(arr)
        }
    }

    private func getClob(index: Int64): Option<InputStream> {
        var buffer = readVarColumn(index, SQL_C_CHAR)
        if (buffer.data.isNull()) {
            return None
        } else {
            var colValuePtr = CPointer<Byte>(buffer.data)
            var arr = Array<Byte>(buffer.len, repeat: 0)
            for (i in 0..buffer.len) {
                arr[i] = unsafe { colValuePtr.read(i) }
            }

            unsafe { LibC.free(buffer.data) }
            var stream = ByteBuffer()
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
            var arr = Array<Byte>(buffer.len, repeat: 0)
            for (i in 0..buffer.len) {
                arr[i] = unsafe { colValuePtr.read(i) }
            }
            unsafe { LibC.free(buffer.data) }
            var stream = ByteBuffer()
            stream.write(arr)
            return Some(stream)
        }
    }

    private func getBool(index: Int64): Option<Bool> {
        let colValueSize = 1
        var res: Option<Bool> = None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_1) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (sizePtr.isNull()) {
            unsafe { free(colValueUnitPtr) }
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_STINYINT, colValueUnitPtr, colValueSize,
            sizePtr) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw exception
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
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_1) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (sizePtr.isNull()) {
            unsafe { free(colValueUnitPtr) }
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_STINYINT, colValueUnitPtr, colValueSize,
            sizePtr) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw exception
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
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_2) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (sizePtr.isNull()) {
            unsafe { free(colValueUnitPtr) }
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_SSHORT, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw exception
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
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_4) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (sizePtr.isNull()) {
            unsafe { free(colValueUnitPtr) }
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_SLONG, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw exception
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
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_8) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (sizePtr.isNull()) {
            unsafe { free(colValueUnitPtr) }
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_SBIGINT, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw exception
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
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_4) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (sizePtr.isNull()) {
            unsafe { free(colValueUnitPtr) }
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_FLOAT, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw exception
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
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_8) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (sizePtr.isNull()) {
            unsafe { free(colValueUnitPtr) }
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_DOUBLE, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw exception
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

    private func getDate(index: Int64): Option<OdbcTypeDate> {
        let colValueSize = 6
        var res = Option<OdbcTypeDate>.None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_6) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (sizePtr.isNull()) {
            unsafe { free(colValueUnitPtr) }
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_TYPE_DATE, colValueUnitPtr, colValueSize,
            sizePtr) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw exception
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<DATE_STRUCT>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            var timestamp = DateTime.of(
                year: Int64(colValue.year),
                month: Int64(colValue.month),
                dayOfMonth: Int64(colValue.day)
            )
            res = Some(OdbcTypeDate(timestamp))
        }

        unsafe {
            free(colValueUnitPtr)
            free(CPointer<Unit>(sizePtr))
        }
        return res
    }

    private func getTime(index: Int64): Option<OdbcTypeTime> {
        let colValueSize = 6
        var res = Option<OdbcTypeTime>.None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_6) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (sizePtr.isNull()) {
            unsafe { free(colValueUnitPtr) }
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_TYPE_TIME, colValueUnitPtr, colValueSize,
            sizePtr) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw exception
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
                second: Int64(colValue.second)
            )
            res = Some(OdbcTypeTime(timestamp))
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
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_16) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (sizePtr.isNull()) {
            unsafe { free(colValueUnitPtr) }
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_TYPE_TIMESTAMP, colValueUnitPtr, colValueSize,
            sizePtr) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw exception
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

    private func getDecimal(index: Int64): Option<Decimal> {
        var buffer = readVarColumn(index, SQL_C_CHAR)
        if (buffer.data.isNull()) {
            return None
        } else {
            var colValue = CString(CPointer<UInt8>(buffer.data))
            var ret = Some(Decimal.parse(colValue.toString()))
            unsafe { LibC.free(buffer.data) }
            return ret
        }
    }

    public override func close(): Unit {
        if (isClosed()) {
            return
        }
        closed.store(true)
    }

    public override func isClosed(): Bool {
        return closed.load()
    }

    private func checkResource() {
        if (isClosed()) {
            throw SqlException("The database Connection has been closed")
        }
    }

    private func readOldVarColumn(index: Int64, ctype: Int16): DataBuffer {
        var cbNullTerminator = 1
        if (ctype == SQL_BINARY || ctype == SQL_VARBINARY || ctype == SQL_LONGVARBINARY) {
            cbNullTerminator = 0
        }

        var cbAllocated = resultCount[index].displaySize
        var cbUsed = 0
        var pb = CPointer<Unit>(LibC.malloc<Int8>(count: cbAllocated))
        if (pb.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var cbData = LibC.malloc<Int64>()
        if (cbData.isNull()) {
            unsafe { LibC.free(pb) }
            throw SqlException("Native malloc failed.")
        }
        var ret = SQL_SUCCESS_WITH_INFO

        var isNull = false

        do {
            var cbAvailable = cbAllocated - cbUsed
            unsafe { cbData.write(0) }
            ret = unsafe { SQLGetData(this.STMT_handle, index + 1, ctype, pb + cbUsed, cbAllocated, cbData) }

            if (!SQLSucceeded(ret) && ret != SQL_NO_DATA) {
                diagnoseException(SQL_HANDLE_STMT, STMT_handle)
                unsafe {
                    LibC.free(pb)
                    LibC.free(cbData)
                }
                return DataBuffer()
            }

            var data = unsafe { cbData.read() }
            if (ret == SQL_SUCCESS && data < 0) {
                ret = Int16(SQL_NULL_DATA)
                unsafe { cbData.write(0) }
                isNull = true
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
                            LibC.free(pb)
                            LibC.free(cbData)
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
            unsafe { LibC.free(cbData) }
            return buffer
        } else {
            if(!isNull){
                var buffer = DataBuffer()
                buffer.data = pb
                buffer.len = cbUsed
                unsafe { LibC.free(cbData) }
                return buffer
            }
            unsafe {
                LibC.free(pb)
                LibC.free(cbData)
            }
            return DataBuffer()
        }
    }

    private func getOldString(index: Int64): Option<String> {
        var buffer = readOldVarColumn(index, SQL_C_CHAR)
        if (buffer.data.isNull()) {
            return None
        } else {
            var colValue = CString(CPointer<UInt8>(buffer.data))
            var ret = Some(colValue.toString())
            unsafe { LibC.free(buffer.data) }
            return ret
        }
    }

    private func getOldBytes(index: Int64): Option<Array<Byte>> {
        var buffer = readOldVarColumn(index, SQL_C_BINARY)
        if (buffer.data.isNull()) {
            return None
        } else {
            var colValuePtr = CPointer<Byte>(buffer.data)
            var arr = Array<Byte>(buffer.len, repeat: 0)
            for (i in 0..buffer.len) {
                arr[i] = unsafe { colValuePtr.read(i) }
            }
            unsafe { LibC.free(buffer.data) }
            return Some(arr)
        }
    }

    private func getOldClob(index: Int64): Option<InputStream> {
        var buffer = readOldVarColumn(index, SQL_C_CHAR)
        if (buffer.data.isNull()) {
            return None
        } else {
            var colValuePtr = CPointer<Byte>(buffer.data)
            var arr = Array<Byte>(buffer.len, repeat: 0)
            for (i in 0..buffer.len) {
                arr[i] = unsafe { colValuePtr.read(i) }
            }

            unsafe { LibC.free(buffer.data) }
            var stream = ByteBuffer()
            stream.write(arr)
            return Some(stream)
        }
    }

    private func getOldBlob(index: Int64): Option<InputStream> {
        var buffer = readOldVarColumn(index, SQL_C_BINARY)
        if (buffer.data.isNull()) {
            return None
        } else {
            var colValuePtr = CPointer<Byte>(buffer.data)
            var arr = Array<Byte>(buffer.len, repeat: 0)
            for (i in 0..buffer.len) {
                arr[i] = unsafe { colValuePtr.read(i) }
            }

            unsafe { LibC.free(buffer.data) }
            var stream = ByteBuffer()
            stream.write(arr)
            return Some(stream)
        }
    }

    private func getOldBool(index: Int64): Option<Bool> {
        let colValueSize = 1
        var res: Option<Bool> = None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_1) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (sizePtr.isNull()) {
            unsafe { free(colValueUnitPtr) }
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_STINYINT, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw exception
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

    private func getOldInt8(index: Int64): Option<Int8> {
        let colValueSize = 1
        var res: Option<Int8> = None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_1) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (sizePtr.isNull()) {
            unsafe { free(colValueUnitPtr) }
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_STINYINT, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw exception
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

    private func getOldInt16(index: Int64): Option<Int16> {
        let colValueSize = 2
        var res: Option<Int16> = None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_2) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (sizePtr.isNull()) {
            unsafe { free(colValueUnitPtr) }
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_SSHORT, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw exception
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

    private func getOldInt32(index: Int64): Option<Int32> {
        let colValueSize = 4
        var res: Option<Int32> = None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_4) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (sizePtr.isNull()) {
            unsafe { free(colValueUnitPtr) }
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_SLONG, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw exception
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

    private func getOldInt64(index: Int64): Option<Int64> {
        let colValueSize = 8
        var res: Option<Int64> = None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_8) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (sizePtr.isNull()) {
            unsafe { free(colValueUnitPtr) }
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_SBIGINT, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw exception
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

    private func getOldFloat32(index: Int64): Option<Float32> {
        let colValueSize = 4
        var res: Option<Float32> = None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_4) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (sizePtr.isNull()) {
            unsafe { free(colValueUnitPtr) }
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_FLOAT, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw exception
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

    private func getOldFloat64(index: Int64): Option<Float64> {
        let colValueSize = 8
        var res: Option<Float64> = None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_8) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (sizePtr.isNull()) {
            unsafe { free(colValueUnitPtr) }
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_DOUBLE, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw exception
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

    private func getOldDate(index: Int64): Option<DateTime> {
        let colValueSize = 6
        var res = Option<DateTime>.None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_6) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (sizePtr.isNull()) {
            unsafe { free(colValueUnitPtr) }
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_TYPE_DATE, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw exception
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<DATE_STRUCT>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            var timestamp = DateTime.of(
                year: Int64(colValue.year),
                month: Int64(colValue.month),
                dayOfMonth: Int64(colValue.day)
            )
            res = Some(timestamp)
        }

        unsafe {
            free(colValueUnitPtr)
            free(CPointer<Unit>(sizePtr))
        }
        return res
    }

    private func getOldTime(index: Int64): Option<DateTime> {
        let colValueSize = 6
        var res = Option<DateTime>.None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_6) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (sizePtr.isNull()) {
            unsafe { free(colValueUnitPtr) }
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_TYPE_TIME, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw exception
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
                second: Int64(colValue.second)
            )
            res = Some(timestamp)
        }

        unsafe {
            free(colValueUnitPtr)
            free(CPointer<Unit>(sizePtr))
        }
        return res
    }

    private func getOldTimestampWithoutTz(index: Int64): Option<DateTime> {
        let colValueSize = 16
        var res = Option<DateTime>.None
        var colValueUnitPtr = CPointer<Unit>(unsafe { malloc(LEN_MALLOC_16) })
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(unsafe { malloc(LEN_MALLOC_8) })
        if (sizePtr.isNull()) {
            unsafe { free(colValueUnitPtr) }
            throw SqlException("Native malloc failed.")
        }
        var ret = unsafe { SQLGetData(this.STMT_handle, index + 1, SQL_C_TYPE_TIMESTAMP, colValueUnitPtr, colValueSize, sizePtr) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            unsafe {
                free(colValueUnitPtr)
                free(CPointer<Unit>(sizePtr))
            }
            throw exception
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

    private func getOldDecimal(index: Int64): Option<Decimal> {
        var buffer = readOldVarColumn(index, SQL_C_CHAR)
        if (buffer.data.isNull()) {
            return None
        } else {
            var colValue = CString(CPointer<UInt8>(buffer.data))
            var ret = Some(Decimal.parse(colValue.toString()))
            unsafe { LibC.free(buffer.data) }
            return ret
        }
    }
}
