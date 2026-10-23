package odbc4cj

/* 执行 Select 语句产生的结果接口 */
public class OdbcQueryResult <: QueryResult {
    private let nativeApi: OdbcNativeApi
    private var resultCount: Array<OdbcColumnInfo>
    private var STMT_handle: CPointer<Unit>
    private let closed = AtomicBool(false)
    private var resultSet: Array<Any>
    // 是否为高斯数据库（zenith 驱动要求 SQL_C_UBIGINT 读取 BIGINT，其他数据库使用 SQL_C_SBIGINT）
    private let isGaussDB: Bool

    init(nativeApi: OdbcNativeApi, STMT_handle: CPointer<Unit>, resultCount: Array<OdbcColumnInfo>,
        isGaussDB: Bool) {
        this.nativeApi = nativeApi
        this.STMT_handle = STMT_handle
        this.resultCount = resultCount
        this.resultSet = Array<Any>(resultCount.size, repeat: Option<Any>.None)
        this.isGaussDB = isGaussDB
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
     * 异常 SqlException - 传入参数错误，或取数失败（SQL_ERROR 等会抛出诊断异常而非静默返回 false）
     */
    public override func next(): Bool {
        checkResource()

        if (STMT_handle.isNull()) {
            throw SqlException("STMT handle is Null.")
        }
        var res = nativeApi.sqlFetch(STMT_handle)
        if (res == SQL_NO_DATA) {
            return false
        } else if (SQLSucceeded(res)) {
            fillResultSet()
            return true
        } else {
            //取数失败必须抛出诊断异常，不能伪装成结果集结束静默丢行
            throw nativeApi.diagnoseException(SQL_HANDLE_STMT, STMT_handle)
        }
    }

    private func fillResultSet(): Unit {
        for (i in 0..resultCount.size) {
            // 新版 next() 按原始 ODBC 类型码分发，不依赖 typeName：
            // 旧版 next(values) 的契约行为会把 typeName 改写为旧版名，typeName 不能作为新版分发依据
            match (resultCount[i].rawSqlType) {
                case 1 | 12 | -8 | -9 => resultSet[i] = getString(i) // SQL_CHAR| SQL_VARCHAR| SQL_WCHAR| SQL_WVARCHAR
                case -2 | -3 => resultSet[i] = getBytes(i) // SQL_BINARY| SQL_VARBINARY
                case -1 | -10 => resultSet[i] = getClob(i) // SQL_LONGVARCHAR| SQL_WLONGVARCHAR
                case -4 => resultSet[i] = getBlob(i) // SQL_LONGVARBINARY
                case -7 => resultSet[i] = getBool(i) // SQL_BIT
                // 无符号列（SQL_DESC_UNSIGNED）路由到 UInt 通道，避免有符号读取溢出（如 int unsigned 的 4294967295）
                case -6 => resultSet[i] = if (resultCount[i].isUnsigned) { getUInt8(i) } else { getInt8(i) } // SQL_TINYINT
                case 5 => resultSet[i] = if (resultCount[i].isUnsigned) { getUInt16(i) } else { getInt16(i) } // SQL_SMALLINT
                case 4 => resultSet[i] = if (resultCount[i].isUnsigned) { getUInt32(i) } else { getInt32(i) } // SQL_INTEGER
                case -5 => resultSet[i] = if (resultCount[i].isUnsigned) { getUInt64(i) } else { getInt64(i) } // SQL_BIGINT
                case 7 => resultSet[i] = getFloat32(i) // SQL_REAL
                case 6 | 8 => resultSet[i] = getFloat64(i) // SQL_FLOAT| SQL_DOUBLE
                case 91 => resultSet[i] = match (getDate(i)) { // SQL_TYPE_DATE
                    case Some(t) => Some(OdbcTypeDate(t))
                    case None => Option<OdbcTypeDate>.None
                }
                case 92 => resultSet[i] = match (getTime(i)) { // SQL_TYPE_TIME
                    case Some(t) => Some(OdbcTypeTime(t))
                    case None => Option<OdbcTypeTime>.None
                }
                case 93 => resultSet[i] = getTimestampWithoutTz(i) // SQL_TYPE_TIMESTAMP
                case 3 | 2 => resultSet[i] = getDecimal(i) // SQL_DECIMAL| SQL_NUMERIC
                case _ =>
                    // 未映射的列类型（如 SQL_GUID/SQL_INTERVAL_*）不拖垮整行：该列以 NULL 占位，其余列正常读取
                    resultSet[i] = Option<Any>.None
            }
        }
    }

    /*
     * 向后移动一行，并把当前行数据以旧版 SqlDbType 形式填入 values
     *
     * 参数 values - 承载当前行数据的数组，长度需与结果集列数一致
     * 返回值 Bool - 存在下一行则返回true，否则返回false
     */
    @Deprecated
    public override func next(values: Array<SqlDbType>): Bool {
        checkResource()
        if (STMT_handle.isNull()) {
            throw SqlException("STMT handle is Null.")
        }
        if (values.size != resultCount.size) {
            throw SqlException("wrong number of values.")
        }
        var res = nativeApi.sqlFetch(STMT_handle)
        if (res == SQL_NO_DATA) {
            return false
        } else if (SQLSucceeded(res)) {
            for (i in 0..values.size) {
                // 旧版契约：next(values) 调用后 columnInfos 的 typeName 必须呈现为旧版名
                // （用例断言依赖此行为），同时新版 next() 的分发已改按 rawSqlType，互不影响
                let colInfo = resultCount[i]
                let oldName = getOldTypeName(colInfo.rawSqlType, colInfo.nullable)
                colInfo.updateTypeName(oldName)
                // 按调用方数组元素的类型分发读取，读取方式由调用方决定
                match (values[i]) {
                    case v: SqlChar => v.value = getString(i).getOrThrow()
                    case v: SqlNullableChar => v.value = getString(i)
                    case v: SqlVarchar => v.value = getString(i).getOrThrow()
                    case v: SqlNullableVarchar => v.value = getString(i)
                    case v: SqlBinary => v.value = getBytes(i).getOrThrow()
                    case v: SqlNullableBinary => v.value = getBytes(i)
                    case v: SqlVarBinary => v.value = getBytes(i).getOrThrow()
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
                    case v: SqlInteger => v.value = getInt32(i).getOrThrow()
                    case v: SqlNullableInteger => v.value = getInt32(i)
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
                    case v: SqlDecimal => v.value = getDecimal(i).getOrThrow()
                    case v: SqlNullableDecimal => v.value = getDecimal(i)
                    case _ => throw SqlException("Unsupported data type.")
                }
            }
            return true
        } else {
            //取数失败必须抛出诊断异常，不能伪装成结果集结束静默丢行
            throw nativeApi.diagnoseException(SQL_HANDLE_STMT, STMT_handle)
        }
    }

    // 旧版 SqlDbType 类型名：根据原始 ODBC 类型码和列是否可空推导
    private func getOldTypeName(dataType: Int16, nullable: Bool): String {
        match (dataType) {
            case -5 => if (nullable) { "SqlNullableBigInt" } else { "SqlBigInt" } // SQL_BIGINT
            case 4 => if (nullable) { "SqlNullableInteger" } else { "SqlInteger" } // SQL_INTEGER
            case 5 => if (nullable) { "SqlNullableSmallInt" } else { "SqlSmallInt" } // SQL_SMALLINT
            case -6 => if (nullable) { "SqlNullableByte" } else { "SqlByte" } // SQL_TINYINT
            case -7 => if (nullable) { "SqlNullableBool" } else { "SqlBool" } // SQL_BIT
            case 7 => if (nullable) { "SqlNullableReal" } else { "SqlReal" } // SQL_REAL
            case 6 | 8 => if (nullable) { "SqlNullableDouble" } else { "SqlDouble" } // SQL_FLOAT| SQL_DOUBLE
            case 1 | -8 => if (nullable) { "SqlNullableChar" } else { "SqlChar" } // SQL_CHAR| SQL_WCHAR
            case 12 | -9 => if (nullable) { "SqlNullableVarchar" } else { "SqlVarchar" } // SQL_VARCHAR| SQL_WVARCHAR
            case -2 => if (nullable) { "SqlNullableBinary" } else { "SqlBinary" } // SQL_BINARY
            case -3 => if (nullable) { "SqlNullableVarBinary" } else { "SqlVarBinary" } // SQL_VARBINARY
            case -1 | -10 => if (nullable) { "SqlNullableClob" } else { "SqlClob" } // SQL_LONGVARCHAR| SQL_WLONGVARCHAR
            case -4 => if (nullable) { "SqlNullableBlob" } else { "SqlBlob" } // SQL_LONGVARBINARY
            case 3 | 2 => if (nullable) { "SqlNullableDecimal" } else { "SqlDecimal" } // SQL_DECIMAL| SQL_NUMERIC
            case 91 => if (nullable) { "SqlNullableDate" } else { "SqlDate" } // SQL_TYPE_DATE
            case 92 => if (nullable) { "SqlNullableTime" } else { "SqlTime" } // SQL_TYPE_TIME
            case 93 => if (nullable) { "SqlNullableTimestampWithoutTz" } else { "SqlTimestampWithoutTz" } // SQL_TYPE_TIMESTAMP
            case _ => "OTHER"
        }
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
        if (index < 0) {
            throw SqlException("Index must be greater than or equal to 0")
        }
        if (index >= resultCount.size) {
            throw SqlException("parameter index error")
        }
        return (resultSet[index] as ?T) ?? throw SqlException("data type error")
    }

    // 宽字符/二进制大字段读取缓冲按 UTF-8 最坏情况扩容，防止截断
    @OverflowSaturating
    private func readVarColumn(index: Int64, ctype: Int16): DataBuffer {
        var cbNullTerminator = 1
        if (ctype == SQL_BINARY || ctype == SQL_VARBINARY || ctype == SQL_LONGVARBINARY) {
            cbNullTerminator = 0
        }

        // 初始缓冲：列大小*3（UTF-8 最坏情况）；过小给默认值、过大截为上限，
        // 防止驱动对无限制列（如 varchar(max)）报 0 或超大值导致负长度读取/巨量分配，超出部分由循环扩容兜底
        var cbAllocated = resultCount[index].displaySize * 3
        if (cbAllocated < 4096) {
            cbAllocated = 4096
        } else if (cbAllocated > 16 * 1024 * 1024) {
            cbAllocated = 16 * 1024 * 1024
        }
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
            // 必须传入本轮真实剩余空间 cbAvailable 而非总容量 cbAllocated，否则多轮循环时驱动可越界写
            ret = nativeApi.sqlGetData(this.STMT_handle, UInt16(index + 1), ctype, unsafe { pb + cbUsed }, cbAvailable,
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
            // memcpy 批量拷贝，避免大字段逐字节 FFI 调用
            var arr = Array<Byte>(buffer.len, repeat: 0)
            let dst = unsafe { acquireArrayRawData(arr) }
            unsafe { nativeApi.memcpy(dst.pointer, buffer.data, UIntNative(buffer.len)) }
            unsafe { releaseArrayRawData(dst) }
            nativeApi.free(buffer.data)
            return Some(arr)
        }
    }

    private func getClob(index: Int64): Option<InputStream> {
        var buffer = readVarColumn(index, SQL_C_CHAR)
        if (buffer.data.isNull()) {
            return None
        } else {
            // memcpy 批量拷贝，避免大字段逐字节 FFI 调用
            var arr = Array<Byte>(buffer.len, repeat: 0)
            let dst = unsafe { acquireArrayRawData(arr) }
            unsafe { nativeApi.memcpy(dst.pointer, buffer.data, UIntNative(buffer.len)) }
            unsafe { releaseArrayRawData(dst) }
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
            // memcpy 批量拷贝，避免大字段逐字节 FFI 调用
            var arr = Array<Byte>(buffer.len, repeat: 0)
            let dst = unsafe { acquireArrayRawData(arr) }
            unsafe { nativeApi.memcpy(dst.pointer, buffer.data, UIntNative(buffer.len)) }
            unsafe { releaseArrayRawData(dst) }
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
        // 高斯 zenith 驱动要求以 SQL_C_UBIGINT 读取 BIGINT，其他数据库使用标准 SQL_C_SBIGINT；
        // 两者位模式相同（8 字节），按位读入 Int64 缓冲对合法 BIGINT 值结果一致
        var ctype = if (isGaussDB) { SQL_C_UBIGINT } else { SQL_C_SBIGINT }
        var ret = nativeApi.sqlGetData(this.STMT_handle, UInt16(index + 1), ctype, colValueUnitPtr, colValueSize,
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
