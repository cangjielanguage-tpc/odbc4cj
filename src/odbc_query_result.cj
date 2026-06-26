package odbc4cj

/* 执行 Select 语句产生的结果接口 */
public class OdbcQueryResult <: QueryResult {
    private let nativeApi: OdbcNativeApi
    private var resultCount: Array<OdbcColumnInfo>
    private var STMT_handle: CPointer<Unit>
    private let closed = AtomicBool(false)
    private var resultSet: Array<Any>

    init(nativeApi: OdbcNativeApi, STMT_handle: CPointer<Unit>, resultCount: Array<OdbcColumnInfo>) {
        this.nativeApi = nativeApi
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
        checkResource()

        if (STMT_handle.isNull()) {
            throw SqlException("STMT handle is Null.")
        }
        var res = nativeApi.sqlFetch(STMT_handle)
        if (res == SQL_NO_DATA) {
            return false
        } else {
            for (i in 0..resultCount.size) {
                match (resultCount[i].typeName) {
                    case "VARCHAR" => resultSet[i] = getString(i)
                    case "VARBINARY" => resultSet[i] = getBytes(i)
                    case "BLOB" => resultSet[i] = getBlob(i)
                    case "CLOB" => resultSet[i] = getClob(i)
                    case "BOOLEAN" => resultSet[i] = getBool(i)
                    case "TINYINT" => resultSet[i] = getInt8(i)
                    case "SMALLINT" => resultSet[i] = getInt16(i)
                    case "INTEGER" => resultSet[i] = getInt32(i)
                    case "BIGINT" => resultSet[i] = getInt64(i)
                    case "REAL" => resultSet[i] = getFloat32(i)
                    case "DOUBLE" => resultSet[i] = getFloat64(i)
                    case "DATE" => resultSet[i] = getDate(i)
                    case "TIME" => resultSet[i] = getTime(i)
                    case "TIMESTAMP" => resultSet[i] = getTimestampWithoutTz(i)
                    case "DECIMAL" => resultSet[i] = getDecimal(i)
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
        return getOrNull<T>(index) ?? throw SqlException("data is null")
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
        if (index < 1) {
            throw SqlException("Index must be greater than or equal to 1")
        }
        if (index > resultCount.size) {
            throw SqlException("parameter index error")
        }
        // 1-based index 转0-based 内部下标
        return (resultSet[index - 1] as ?T) ?? throw SqlException("data type error")
    }

    /**
     * 向后移动一行，必须先调用一次 next 才能移动到第一行，第二次调用移动到第二行，依此类推。
     * 当返回 true 时，驱动会在 values 中填入行数据；当返回 false 时结束，且不会修改 values 的内容。
     * 返回值 Bool - 存在下一行则返回 true，否则返回 false
     */
    @Deprecated
    public override func next(values: Array<SqlDbType>): Bool {
        throw UnsupportedException("This method is deprecated, please use next() instead.")
    }

    private func readVarColumn(index: Int64, ctype: Int16): DataBuffer {
        var cbNullTerminator = 1
        if (ctype == SQL_BINARY || ctype == SQL_VARBINARY || ctype == SQL_LONGVARBINARY) {
            cbNullTerminator = 0
        }

        var cbAllocated = resultCount[index].displaySize
        var cbUsed = 0
        var pb: CPointer<Unit> = nativeApi.malloc(UIntNative(cbAllocated))
        if (pb.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var cbData = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (cbData.isNull()) {
            nativeApi.free(pb)
            throw SqlException("Native malloc failed.")
        }
        var ret = SQL_SUCCESS_WITH_INFO

        var isNull = false

        do {
            var cbAvailable = cbAllocated - cbUsed
            unsafe { cbData.write(0) }
            ret = nativeApi.sqlGetData(this.STMT_handle, UInt16(index + 1), ctype, unsafe { pb + cbUsed }, cbAllocated,
                cbData)

            if (!SQLSucceeded(ret) && ret != SQL_NO_DATA) {
                nativeApi.free(pb)
                nativeApi.free(CPointer<Unit>(cbData))
                throw nativeApi.diagnoseException(SQL_HANDLE_STMT, STMT_handle)
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
                    var ptr = nativeApi.realloc(pb, cbNeed)
                    if (ptr.isNull()) {
                        nativeApi.free(pb)
                        nativeApi.free(CPointer<Unit>(cbData))
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
            nativeApi.free(CPointer<Unit>(cbData))
            return buffer
        } else {
            if (!isNull) {
                var buffer = DataBuffer()
                buffer.data = pb
                buffer.len = cbUsed
                nativeApi.free(CPointer<Unit>(cbData))
                return buffer
            }
            nativeApi.free(pb)
            nativeApi.free(CPointer<Unit>(cbData))
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
            nativeApi.free(buffer.data)
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
            nativeApi.free(buffer.data)
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

            nativeApi.free(buffer.data)
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
            nativeApi.free(buffer.data)
            var stream = ByteBuffer()
            stream.write(arr)
            return Some(stream)
        }
    }

    private func getBool(index: Int64): Option<Bool> {
        let colValueSize = 1
        var res: Option<Bool> = None
        var colValueUnitPtr = nativeApi.malloc(LEN_MALLOC_1)
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (sizePtr.isNull()) {
            nativeApi.free(colValueUnitPtr)
            throw SqlException("Native malloc failed.")
        }
        var ret = nativeApi.sqlGetData(this.STMT_handle, UInt16(index + 1), SQL_C_STINYINT, colValueUnitPtr,
            colValueSize, sizePtr)
        if (!SQLSucceeded(ret)) {
            var exception = nativeApi.diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            nativeApi.free(colValueUnitPtr)
            nativeApi.free(CPointer<Unit>(sizePtr))
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

        nativeApi.free(colValueUnitPtr)
        nativeApi.free(CPointer<Unit>(sizePtr))
        return res
    }

    private func getInt8(index: Int64): Option<Int8> {
        let colValueSize = 1
        var res: Option<Int8> = None
        var colValueUnitPtr = nativeApi.malloc(LEN_MALLOC_1)
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (sizePtr.isNull()) {
            nativeApi.free(colValueUnitPtr)
            throw SqlException("Native malloc failed.")
        }
        var ret = nativeApi.sqlGetData(this.STMT_handle, UInt16(index + 1), SQL_C_STINYINT, colValueUnitPtr,
            colValueSize, sizePtr)
        if (!SQLSucceeded(ret)) {
            var exception = nativeApi.diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            nativeApi.free(colValueUnitPtr)
            nativeApi.free(CPointer<Unit>(sizePtr))
            throw exception
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<Int8>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            res = Some(colValue)
        }

        nativeApi.free(colValueUnitPtr)
        nativeApi.free(CPointer<Unit>(sizePtr))
        return res
    }

    private func getInt16(index: Int64): Option<Int16> {
        let colValueSize = 2
        var res: Option<Int16> = None
        var colValueUnitPtr = nativeApi.malloc(LEN_MALLOC_2)
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (sizePtr.isNull()) {
            nativeApi.free(colValueUnitPtr)
            throw SqlException("Native malloc failed.")
        }
        var ret = nativeApi.sqlGetData(this.STMT_handle, UInt16(index + 1), SQL_C_SSHORT, colValueUnitPtr, colValueSize,
            sizePtr)
        if (!SQLSucceeded(ret)) {
            nativeApi.free(colValueUnitPtr)
            nativeApi.free(CPointer<Unit>(sizePtr))
            throw nativeApi.diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<Int16>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            res = Some(colValue)
        }

        nativeApi.free(colValueUnitPtr)
        nativeApi.free(CPointer<Unit>(sizePtr))
        return res
    }

    private func getInt32(index: Int64): Option<Int32> {
        let colValueSize = 4
        var res: Option<Int32> = None
        var colValueUnitPtr = nativeApi.malloc(LEN_MALLOC_4)
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (sizePtr.isNull()) {
            nativeApi.free(colValueUnitPtr)
            throw SqlException("Native malloc failed.")
        }
        var ret = nativeApi.sqlGetData(this.STMT_handle, UInt16(index + 1), SQL_C_SLONG, colValueUnitPtr, colValueSize,
            sizePtr)
        if (!SQLSucceeded(ret)) {
            nativeApi.free(colValueUnitPtr)
            nativeApi.free(CPointer<Unit>(sizePtr))
            throw nativeApi.diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<Int32>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            res = Some(colValue)
        }

        nativeApi.free(colValueUnitPtr)
        nativeApi.free(CPointer<Unit>(sizePtr))
        return res
    }

    private func getInt64(index: Int64): Option<Int64> {
        let colValueSize = 8
        var res: Option<Int64> = None
        var colValueUnitPtr = nativeApi.malloc(LEN_MALLOC_8)
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (sizePtr.isNull()) {
            nativeApi.free(colValueUnitPtr)
            throw SqlException("Native malloc failed.")
        }
        var ret = nativeApi.sqlGetData(this.STMT_handle, UInt16(index + 1), SQL_C_SBIGINT, colValueUnitPtr, colValueSize,
            sizePtr)
        if (!SQLSucceeded(ret)) {
            nativeApi.free(colValueUnitPtr)
            nativeApi.free(CPointer<Unit>(sizePtr))
            throw nativeApi.diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<Int64>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            res = Some(colValue)
        }

        nativeApi.free(colValueUnitPtr)
        nativeApi.free(CPointer<Unit>(sizePtr))
        return res
    }

    private func getFloat32(index: Int64): Option<Float32> {
        let colValueSize = 4
        var res: Option<Float32> = None
        var colValueUnitPtr = nativeApi.malloc(LEN_MALLOC_4)
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (sizePtr.isNull()) {
            nativeApi.free(colValueUnitPtr)
            throw SqlException("Native malloc failed.")
        }
        var ret = nativeApi.sqlGetData(this.STMT_handle, UInt16(index + 1), SQL_C_FLOAT, colValueUnitPtr, colValueSize,
            sizePtr)
        if (!SQLSucceeded(ret)) {
            nativeApi.free(colValueUnitPtr)
            nativeApi.free(CPointer<Unit>(sizePtr))
            throw nativeApi.diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<Float32>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            res = Some(colValue)
        }

        nativeApi.free(colValueUnitPtr)
        nativeApi.free(CPointer<Unit>(sizePtr))
        return res
    }

    private func getFloat64(index: Int64): Option<Float64> {
        let colValueSize = 8
        var res: Option<Float64> = None
        var colValueUnitPtr = nativeApi.malloc(LEN_MALLOC_8)
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (sizePtr.isNull()) {
            nativeApi.free(colValueUnitPtr)
            throw SqlException("Native malloc failed.")
        }
        var ret = nativeApi.sqlGetData(this.STMT_handle, UInt16(index + 1), SQL_C_DOUBLE, colValueUnitPtr, colValueSize,
            sizePtr)
        if (!SQLSucceeded(ret)) {
            nativeApi.free(colValueUnitPtr)
            nativeApi.free(CPointer<Unit>(sizePtr))
            throw nativeApi.diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<Float64>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            res = Some(colValue)
        }

        nativeApi.free(colValueUnitPtr)
        nativeApi.free(CPointer<Unit>(sizePtr))
        return res
    }

    private func getDate(index: Int64): Option<DateTime> {
        let colValueSize = 6
        var res = Option<DateTime>.None
        var colValueUnitPtr = nativeApi.malloc(LEN_MALLOC_6)
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (sizePtr.isNull()) {
            nativeApi.free(colValueUnitPtr)
            throw SqlException("Native malloc failed.")
        }
        var ret = nativeApi.sqlGetData(this.STMT_handle, UInt16(index + 1), SQL_C_TYPE_DATE, colValueUnitPtr,
            colValueSize, sizePtr)
        if (!SQLSucceeded(ret)) {
            nativeApi.free(colValueUnitPtr)
            nativeApi.free(CPointer<Unit>(sizePtr))
            throw nativeApi.diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
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

        nativeApi.free(colValueUnitPtr)
        nativeApi.free(CPointer<Unit>(sizePtr))
        return res
    }

    private func getTime(index: Int64): Option<DateTime> {
        let colValueSize = 6
        var res = Option<DateTime>.None
        var colValueUnitPtr = nativeApi.malloc(LEN_MALLOC_6)
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (sizePtr.isNull()) {
            nativeApi.free(colValueUnitPtr)
            throw SqlException("Native malloc failed.")
        }
        var ret = nativeApi.sqlGetData(this.STMT_handle, UInt16(index + 1), SQL_C_TYPE_TIME, colValueUnitPtr,
            colValueSize, sizePtr)
        if (!SQLSucceeded(ret)) {
            nativeApi.free(colValueUnitPtr)
            nativeApi.free(CPointer<Unit>(sizePtr))
            throw nativeApi.diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
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

        nativeApi.free(colValueUnitPtr)
        nativeApi.free(CPointer<Unit>(sizePtr))
        return res
    }

    private func getTimestampWithoutTz(index: Int64): Option<DateTime> {
        let colValueSize = 16
        var res = Option<DateTime>.None
        var colValueUnitPtr = nativeApi.malloc(LEN_MALLOC_16)
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (sizePtr.isNull()) {
            nativeApi.free(colValueUnitPtr)
            throw SqlException("Native malloc failed.")
        }
        var ret = nativeApi.sqlGetData(this.STMT_handle, UInt16(index + 1), SQL_C_TYPE_TIMESTAMP, colValueUnitPtr,
            colValueSize, sizePtr)
        if (!SQLSucceeded(ret)) {
            nativeApi.free(colValueUnitPtr)
            nativeApi.free(CPointer<Unit>(sizePtr))
            throw nativeApi.diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
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

        nativeApi.free(colValueUnitPtr)
        nativeApi.free(CPointer<Unit>(sizePtr))
        return res
    }

    private func getDecimal(index: Int64): Option<Decimal> {
        var buffer = readVarColumn(index, SQL_C_CHAR)
        if (buffer.data.isNull()) {
            return None
        } else {
            var colValue = CString(CPointer<UInt8>(buffer.data))
            var ret = Some(Decimal.parse(colValue.toString()))
            nativeApi.free(buffer.data)
            return ret
        }
    }

    private func getUInt8(index: Int64): Option<UInt8> {
        let colValueSize = 1
        var res: Option<UInt8> = None
        var colValueUnitPtr = nativeApi.malloc(LEN_MALLOC_1)
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (sizePtr.isNull()) {
            nativeApi.free(colValueUnitPtr)
            throw SqlException("Native malloc failed.")
        }
        var ret = nativeApi.sqlGetData(this.STMT_handle, UInt16(index + 1), SQL_C_UTINYINT, colValueUnitPtr,
            colValueSize, sizePtr)
        if (!SQLSucceeded(ret)) {
            var exception = nativeApi.diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
            nativeApi.free(colValueUnitPtr)
            nativeApi.free(CPointer<Unit>(sizePtr))
            throw exception
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<UInt8>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            res = Some(colValue)
        }

        nativeApi.free(colValueUnitPtr)
        nativeApi.free(CPointer<Unit>(sizePtr))
        return res
    }

    private func getUInt16(index: Int64): Option<UInt16> {
        let colValueSize = 2
        var res: Option<UInt16> = None
        var colValueUnitPtr = nativeApi.malloc(LEN_MALLOC_2)
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (sizePtr.isNull()) {
            nativeApi.free(colValueUnitPtr)
            throw SqlException("Native malloc failed.")
        }
        var ret = nativeApi.sqlGetData(this.STMT_handle, UInt16(index + 1), SQL_C_USHORT, colValueUnitPtr, colValueSize,
            sizePtr)
        if (!SQLSucceeded(ret)) {
            nativeApi.free(colValueUnitPtr)
            nativeApi.free(CPointer<Unit>(sizePtr))
            throw nativeApi.diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<UInt16>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            res = Some(colValue)
        }

        nativeApi.free(colValueUnitPtr)
        nativeApi.free(CPointer<Unit>(sizePtr))
        return res
    }

    private func getUInt32(index: Int64): Option<UInt32> {
        let colValueSize = 4
        var res: Option<UInt32> = None
        var colValueUnitPtr = nativeApi.malloc(LEN_MALLOC_4)
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (sizePtr.isNull()) {
            nativeApi.free(colValueUnitPtr)
            throw SqlException("Native malloc failed.")
        }
        var ret = nativeApi.sqlGetData(this.STMT_handle, UInt16(index + 1), SQL_C_ULONG, colValueUnitPtr, colValueSize,
            sizePtr)
        if (!SQLSucceeded(ret)) {
            nativeApi.free(colValueUnitPtr)
            nativeApi.free(CPointer<Unit>(sizePtr))
            throw nativeApi.diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<UInt32>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            res = Some(colValue)
        }

        nativeApi.free(colValueUnitPtr)
        nativeApi.free(CPointer<Unit>(sizePtr))
        return res
    }

    private func getUInt64(index: Int64): Option<UInt64> {
        let colValueSize = 8
        var res: Option<UInt64> = None
        var colValueUnitPtr = nativeApi.malloc(LEN_MALLOC_8)
        if (colValueUnitPtr.isNull()) {
            throw SqlException("Native malloc failed.")
        }
        var sizePtr = CPointer<Int64>(nativeApi.malloc(LEN_MALLOC_8))
        if (sizePtr.isNull()) {
            nativeApi.free(colValueUnitPtr)
            throw SqlException("Native malloc failed.")
        }
        var ret = nativeApi.sqlGetData(this.STMT_handle, UInt16(index + 1), SQL_C_UBIGINT, colValueUnitPtr, colValueSize,
            sizePtr)
        if (!SQLSucceeded(ret)) {
            nativeApi.free(colValueUnitPtr)
            nativeApi.free(CPointer<Unit>(sizePtr))
            throw nativeApi.diagnoseException(SQL_HANDLE_STMT, this.STMT_handle)
        }

        if (unsafe { sizePtr.read() } != SQL_NULL_DATA) {
            var colValuePtr = CPointer<UInt64>(colValueUnitPtr)
            var colValue = unsafe { colValuePtr.read() }
            res = Some(colValue)
        }

        nativeApi.free(colValueUnitPtr)
        nativeApi.free(CPointer<Unit>(sizePtr))
        return res
    }

    public override func close(): Unit {
        if (isClosed()) {
            return
        }
        if(!STMT_handle.isNull()) {
            nativeApi.sqlCloseCursor(STMT_handle)
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
}
