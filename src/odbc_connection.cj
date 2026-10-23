package odbc4cj

public open class OdbcConnection <: Connection {
    private let nativeApi: OdbcNativeApi
    private var ENV_handle: CPointer<Unit>
    private var DBC_handlePtr: CPointer<Unit>
    private let closed = AtomicBool(true)
    private var options: HashMap<String, String>
    // 缓存的数据库产品名（SQL_DBMS_NAME），查询一次后不再重复查询
    private var cachedDbmsName: ?String = None
    private var cachedMetaData: ?Map<String, String> = None
    // connection 标识 ID 分配器（单调递增，保证唯一）
    private static let nextObjId = AtomicUInt64(1)
    // connection 标识 ID
    private var objIdValue: UInt64

    /*
     * connection 标识 ID
     */
    public prop objId: UInt64 {
        get() {
            return objIdValue
        }
    }

    /**
     * 初始化数据库连接
     * 通过HashMap 选项连接ODBC 数据源
     */
    init(nativeApi: OdbcNativeApi, options: HashMap<String, String>) {
        this.nativeApi = nativeApi
        this.options = options
        this.objIdValue = OdbcConnection.nextObjId.fetchAdd(1)
        var ret: Int16

        //1.分配环境句柄
        var ENV_handlePtr = nativeApi.malloc(LEN_POINTER)
        if (ENV_handlePtr.isNull()) {
            throw SqlException("Native malloc Failed.")
        }
        let nullHandle = CPointer<Unit>()
        ret = nativeApi.sqlAllocHandle(SQL_HANDLE_ENV, nullHandle, CPointer<CPointer<Unit>>(ENV_handlePtr))
        if (!SQLSucceeded(ret)) {
            nativeApi.free(ENV_handlePtr)
            throw SqlException("Can't initialize module odbc. SQLAllocEnv failed.")
        }
        let envRead = unsafe { CPointer<CPointer<Unit>>(ENV_handlePtr).read() }
        if (envRead.isNull()) {
            nativeApi.free(ENV_handlePtr)
            throw SqlException("Native malloc Failed.")
        }
        this.ENV_handle = envRead

        //2.设置ODBC版本属性
        ret = nativeApi.sqlSetEnvAttr(ENV_handle, SQL_ATTR_ODBC_VERSION, SQL_OV_ODBC3, SQL_IS_INTEGER)
        if (!SQLSucceeded(ret)) {
            nativeApi.sqlFreeHandle(SQL_HANDLE_ENV, ENV_handle)
            nativeApi.free(ENV_handlePtr)
            throw SqlException("Unable to set SQL_ATTR_ODBC_VERSION attribute.")
        }

        //3.分配连接句柄
        var DBC_handlePtrOut = nativeApi.malloc(LEN_POINTER)
        if (DBC_handlePtrOut.isNull()) {
            nativeApi.sqlFreeHandle(SQL_HANDLE_ENV, ENV_handle)
            nativeApi.free(ENV_handlePtr)
            throw SqlException("Native malloc Failed.")
        }
        ret = nativeApi.sqlAllocHandle(SQL_HANDLE_DBC, ENV_handle, CPointer<CPointer<Unit>>(DBC_handlePtrOut))
        if (!SQLSucceeded(ret)) {
            var exception = nativeApi.diagnoseException(SQL_HANDLE_ENV, ENV_handle)
            nativeApi.sqlFreeHandle(SQL_HANDLE_ENV, ENV_handle)
            nativeApi.free(ENV_handlePtr)
            nativeApi.free(DBC_handlePtrOut)
            throw exception
        }
        let dbcRead = unsafe { CPointer<CPointer<Unit>>(DBC_handlePtrOut).read() }
        if (dbcRead.isNull()) {
            nativeApi.sqlFreeHandle(SQL_HANDLE_ENV, ENV_handle)
            nativeApi.free(ENV_handlePtr)
            nativeApi.free(DBC_handlePtrOut)
            throw SqlException("Native malloc Failed.")
        }
        this.DBC_handlePtr = dbcRead
        nativeApi.free(ENV_handlePtr)
        nativeApi.free(DBC_handlePtrOut)

        //4.设置登录超时
        if (let Some(v) <- options.get("SQL_ATTR_LOGIN_TIMEOUT")) {
            var timeoutValue = Int64.parse(v)
            var attrRet = nativeApi.sqlSetConnectAttr(DBC_handlePtr, SQL_ATTR_LOGIN_TIMEOUT, timeoutValue,
                SQL_IS_UINTEGER)
            if (!SQLSucceeded(attrRet)) {
                throw nativeApi.diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
            }
        }

        // 设置连接超时
        if (let Some(v) <- options.get("SQL_ATTR_CONNECTION_TIMEOUT")) {
            var timeoutValue = Int64.parse(v)
            var attrRet = nativeApi.sqlSetConnectAttr(DBC_handlePtr, SQL_ATTR_CONNECTION_TIMEOUT, timeoutValue,
                SQL_IS_UINTEGER)
            if (!SQLSucceeded(attrRet)) {
                throw nativeApi.diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
            }
        }

        //5. 设置连接属性
        if (let Some(v) <- options.get("SQL_ATTR_AUTOCOMMIT")) {
            var valuePtr: Int64
            if (v == "SQL_AUTOCOMMIT_OFF") {
                valuePtr = SQL_AUTOCOMMIT_OFF
            } else if (v == "SQL_AUTOCOMMIT_ON") {
                valuePtr = SQL_AUTOCOMMIT_ON
            } else {
                throw SqlException("SQL_ATTR_AUTOCOMMIT value must be SQL_AUTOCOMMIT_OFF or SQL_AUTOCOMMIT_ON.")
            }
            var attrRet = nativeApi.sqlSetConnectAttr(DBC_handlePtr, SQL_ATTR_AUTOCOMMIT, valuePtr, SQL_IS_UINTEGER)
            if (!SQLSucceeded(attrRet)) {
                throw nativeApi.diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
            }
        }

        //6. 用SqlDriverConnect连接 -inlined buildConnectionString for open class constructor
        var connStr = ""
        if (let Some(url) <- options.get(SqlOption.URL)) {
            if (url.contains(";") || url.contains("=")) {
                connStr = url
            }
        }
        if (connStr.size == 0) {
            var parts = ArrayList<String>()
            if (let Some(v) <- options.get(SqlOption.Database)) {
                parts.add("DSN=${v}")
            }
            if (let Some(v) <- options.get(SqlOption.Username)) {
                parts.add("UID=${v}")
            }
            if (let Some(v) <- options.get(SqlOption.Password)) {
                parts.add("PWD=${v}")
            }
            if (let Some(v) <- options.get(SqlOption.Host)) {
                parts.add("SERVER=${v}")
            }
            var sb = StringBuilder()
            var arr = parts.toArray()
            for (i in 0..arr.size) {
                if (i > 0) {
                    sb.append(";")
                }
                sb.append(arr[i])
            }
            connStr = sb.toString()
        }
        let cConnStr = unsafe { LibC.mallocCString(connStr) }
        if (cConnStr.isNull()) {
            nativeApi.sqlFreeHandle(SQL_HANDLE_DBC, DBC_handlePtr)
            nativeApi.sqlFreeHandle(SQL_HANDLE_ENV, ENV_handle)
            throw SqlException("Native malloc Failed.")
        }
        ret = nativeApi.sqlDriverConnect(DBC_handlePtr, CPointer<Unit>(), cConnStr, SQL_NTS, CPointer<UInt8>(), 0,
            CPointer<Int16>(), SQL_DRIVER_NOPROMPT)
        unsafe { LibC.free(cConnStr) }
        if (!SQLSucceeded(ret)) {
            var exception = nativeApi.diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
            nativeApi.sqlFreeHandle(SQL_HANDLE_DBC, DBC_handlePtr)
            nativeApi.sqlFreeHandle(SQL_HANDLE_ENV, ENV_handle)
            throw exception
        }
        closed.store(false)
    }

    protected func buildConnectionString(options: HashMap<String, String>): String {
        //优先使用完整连接字符串
        if (let Some(url) <- options.get(SqlOption.URL)) {
            if (url.contains(";") || url.contains("=")) {
                return url
            }
        }
        //否则从sqloption各键拼接ODBC连接串
        var parts = ArrayList<String>()
        if (let Some(v) <- options.get(SqlOption.Database)) {
            parts.add("DSN=${v}")
        }
        if (let Some(v) <- options.get(SqlOption.Username)) {
            parts.add("UID=${v}")
        }
        if (let Some(v) <- options.get(SqlOption.Password)) {
            parts.add("PWD=${v}")
        }
        if (let Some(v) <- options.get(SqlOption.Host)) {
            parts.add("SERVER=${v}")
        }
        var sb = StringBuilder()
        var arr = parts.toArray()
        for (i in 0..arr.size) {
            if (i > 0) {
                sb.append(";")
            }
            sb.append(arr[i])
        }
        return sb.toString()
    }

    /**
     * 从options中设置SQL_ATTR_AUTOCOMMIT等连接属性
     */
    protected func applyConnectionAttrs(): Unit {
        if (let Some(v) <- options.get("SQL_ATTR_AUTOCOMMIT")) {
            var valuePtr: Int64
            if (v == "SQL_AUTOCOMMIT_OFF") {
                valuePtr = SQL_AUTOCOMMIT_OFF
            } else if (v == "SQL_AUTOCOMMIT_ON") {
                valuePtr = SQL_AUTOCOMMIT_ON
            } else {
                throw SqlException("SQL_ATTR_AUTOCOMMIT value must be SQL_AUTOCOMMIT_OFF or SQL_AUTOCOMMIT_ON.")
            }
            var ret = nativeApi.sqlSetConnectAttr(DBC_handlePtr, SQL_ATTR_AUTOCOMMIT, valuePtr, SQL_IS_UINTEGER)
            if (!SQLSucceeded(ret)) {
                throw nativeApi.diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
            }
        }
    }

    /**
     * 数据库产品名（SQL_DBMS_NAME），首次访问时查询并缓存
     */
    public prop dbmsName: String {
        get() {
            if (let Some(name) <- cachedDbmsName) {
                return name
            }
            let name = getInfoString(SQL_DBMS_NAME)
            cachedDbmsName = name
            return name
        }
    }

    /**
     * 是否为高斯数据库（zenith 驱动对部分绑定类型支持有限，需要特殊绑定）
     */
    public prop isGaussDB: Bool {
        get() {
            let name = dbmsName.toAsciiLower()
            name.contains("gauss") || name.contains("zenith")
        }
    }

    /**
     * 描述与数据源连接的当前状态
     */
    public override prop state: ConnectionState {
        get() {
            if (closed.load()) {
                Closed
            } else {
                Connected
            }
        }
    }

    /**
     * 返回连接到的数据源元数据，更多信息可使用 getInfo 方法
     * 元数据在连接生命周期内不变，首次构建后缓存
     */
    public override func getMetaData(): Map<String, String> {
        checkResource()
        if (let Some(meta) <- cachedMetaData) {
            return meta
        }
        var meta = HashMap<String, String>()
        meta["driver.name"] = getInfoString(SQL_DRIVER_NAME)
        meta["driver.version"] = getInfoString(SQL_DRIVER_VER)
        meta["dbms.name"] = getInfoString(SQL_DBMS_NAME)
        meta["dbms.version"] = getInfoString(SQL_DBMS_VER)
        meta["server.name"] = getInfoString(SQL_SERVER_NAME)
        meta["data.source.name"] = getInfoString(SQL_DATA_SOURCE_NAME)
        cachedMetaData = meta
        return meta
    }

    /**
     * 返回有关与连接关联的驱动程序和数据源的常规信息，请参考 odbc 接口文档
     * infoType - 信息类型
     * len - 信息长度
     *       UInt16: len = 2
     *       UInt32: len = 4
     *       UInt64: len = 8
     *       String: len > 8
     */
    private func getInfoString(infoType: UInt16): String {
        var bufferLen: Int16 = 256

        var infoValuePtr = unsafe { LibC.malloc<UInt8>(count: Int64(bufferLen)) }
        if (infoValuePtr.isNull()) {
            return ""
        }

        var strLenPtr = CPointer<Int16>(nativeApi.malloc(LEN_MALLOC_2))
        if (strLenPtr.isNull()) {
            unsafe { LibC.free(infoValuePtr) }
            return ""
        }

        var ret = nativeApi.sqlGetInfo(DBC_handlePtr, infoType, CPointer<Unit>(infoValuePtr), bufferLen, strLenPtr)
        if (!SQLSucceeded(ret)) {
            unsafe { LibC.free(infoValuePtr) }
            nativeApi.free(CPointer<Unit>(strLenPtr))
            return ""
        }

        // 驱动返回所需总长度（不含终止符）超过缓冲时扩容重取，避免静默截断
        var needed = unsafe { strLenPtr.read() }
        if (needed >= bufferLen) {
            unsafe { LibC.free(infoValuePtr) }
            infoValuePtr = unsafe { LibC.malloc<UInt8>(count: Int64(needed) + 1) }
            if (infoValuePtr.isNull()) {
                nativeApi.free(CPointer<Unit>(strLenPtr))
                return ""
            }
            ret = nativeApi.sqlGetInfo(DBC_handlePtr, infoType, CPointer<Unit>(infoValuePtr), needed + 1, strLenPtr)
            if (!SQLSucceeded(ret)) {
                unsafe { LibC.free(infoValuePtr) }
                nativeApi.free(CPointer<Unit>(strLenPtr))
                return ""
            }
        }

        // 编码自适应：部分驱动 ANSI 接口返回 UTF-8，部分返回本地代码页（中文 Windows 为 GBK），
        // 固定按 UTF-8 解析本地编码会抛 Invalid unicode scalar value。
        // 先尝试 UTF-8（合法即无损），非法时经 kernel32 MultiByteToWideChar 按当前 ANSI 代码页转 UTF-16
        var bytePtr = CPointer<UInt8>(infoValuePtr)
        var len: Int64 = 0
        while (unsafe { bytePtr.read(len) } != 0) {
            len += 1
        }

        var byteArr = Array<UInt8>(len, repeat: 0)
        for (j in 0..len) {
            byteArr[j] = unsafe { bytePtr.read(j) }
        }

        var decoded: ?String = None
        try {
            decoded = Some(String.fromUtf8(byteArr))
        } catch (e: IllegalArgumentException) {
            var wlen = nativeApi.multiByteToWideChar(0 /*CP_ACP*/, 0, bytePtr, Int32(len), CPointer<UInt16>(), 0)
            if (wlen > 0) {
                var wbufPtr = nativeApi.malloc(UIntNative(wlen) * 2)
                if (!wbufPtr.isNull()) {
                    nativeApi.multiByteToWideChar(0 /*CP_ACP*/, 0, bytePtr, Int32(len), CPointer<UInt16>(wbufPtr), wlen)
                    var unitPtr = CPointer<UInt16>(wbufPtr)
                    var sb = StringBuilder()
                    var k: Int64 = 0
                    while (k < Int64(wlen)) {
                        var unit = unsafe { unitPtr.read(k) }
                        if (unit >= 0xD800 && unit <= 0xDBFF && k + 1 < Int64(wlen)) {
                            var low = unsafe { unitPtr.read(k + 1) }
                            if (low >= 0xDC00 && low <= 0xDFFF) {
                                var cp: UInt32 = 0x10000 + ((UInt32(unit) - 0xD800) << 10) + (UInt32(low) - 0xDC00)
                                sb.append(Rune(cp))
                                k += 2
                                continue
                            }
                        }
                        sb.append(Rune(UInt32(unit)))
                        k += 1
                    }
                    decoded = Some(sb.toString())
                    nativeApi.free(wbufPtr)
                }
            }
        }

        unsafe { LibC.free(infoValuePtr) }
        nativeApi.free(CPointer<Unit>(strLenPtr))

        return match (decoded) {
            case Some(s) => s
            case None => ""
        }
    }

    /**
     * 通过 ODBC infoType 获取连接信息
     * infoType - 信息类型
     * len - 信息长度
     *       UInt16: len = 2
     *       UInt32: len = 4
     *       UInt64: len = 8
     *       String: len > 8
     */
    public func getInfo(infoType: UInt16, len: Int16): String {
        var infoValue: String = ""
        if (!(len == 2 || len == 4 || len >= 8)) {
            throw OdbcSqlException("", "len is not 2, 4 or >=8.", 0)
        }
        unsafe {
            var infoValuePtr = LibC.malloc<Int8>(count: Int64(len))
            if (infoValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            if (DBC_handlePtr.isNull()) {
                LibC.free(infoValuePtr)
                throw SqlException("DBC handle is Null.")
            }
            var ret = nativeApi.sqlGetInfo(DBC_handlePtr, infoType, CPointer<Unit>(infoValuePtr), len,
                CPointer<Int16>())
            if (!SQLSucceeded(ret)) {
                var exception = nativeApi.diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
                LibC.free(infoValuePtr)
                throw exception
            }
            if (len == 2) {
                infoValue = CPointer<UInt16>(infoValuePtr).read().toString()
            } else if (len == 4) {
                infoValue = CPointer<UInt32>(infoValuePtr).read().toString()
            } else if (len == 8) {
                infoValue = CPointer<UInt64>(infoValuePtr).read().toString()
            } else {
                infoValue = CString(CPointer<UInt8>(infoValuePtr)).toString()
            }
            LibC.free(infoValuePtr)
        }
        return infoValue
    }

    /**
     * 通过传入的 sql 语句，返回一个预执行的 Statement 对象实例
     * 参数 sql - 预执行的 sql 语句，sql 语句的参数只支持 ? 符号占位符
     * 返回值 Statement - 一个可以执行 sql 语句的实例对象
     * 异常 SqlException - 语法错误，sql 语句包含不认识的字符
     */
    public override func prepareStatement(sql: String): Statement {
        checkResource()

        var STMT_handlePtr = nativeApi.malloc(LEN_POINTER)
        if (STMT_handlePtr.isNull()) {
            throw SqlException("Native malloc Failed.")
        }

        var ret: Int16 = nativeApi.sqlAllocHandle(SQL_HANDLE_STMT, DBC_handlePtr,
            CPointer<CPointer<Unit>>(STMT_handlePtr))
        if (!SQLSucceeded(ret)) {
            var exception = nativeApi.diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
            nativeApi.free(STMT_handlePtr)
            throw exception
        }
        var STMT_handlePtr1: CPointer<Unit> = unsafe { CPointer<CPointer<Unit>>(STMT_handlePtr).read() }
        nativeApi.free(STMT_handlePtr)
        if (STMT_handlePtr1.isNull()) {
            throw SqlException("Native malloc Failed.")
        }
        let csql = unsafe { LibC.mallocCString(sql) }
        if (csql.isNull()) {
            nativeApi.sqlFreeHandle(SQL_HANDLE_STMT, STMT_handlePtr1)
            throw SqlException("Native malloc Failed.")
        }
        ret = nativeApi.sqlPrepare(STMT_handlePtr1, csql, Int32(SQL_NTS))
        unsafe { LibC.free(csql) }
        if (!SQLSucceeded(ret)) {
            // prepare 的错误诊断挂在语句句柄上，必须用 SQL_HANDLE_STMT 取，否则丢失真实错误信息
            var exception = nativeApi.diagnoseException(SQL_HANDLE_STMT, STMT_handlePtr1)
            nativeApi.sqlFreeHandle(SQL_HANDLE_STMT, STMT_handlePtr1)
            throw exception
        }
        var statement = OdbcStatement(nativeApi, STMT_handlePtr1, this)
        return statement
    }

    /**
     * 创建事务对象
     * 异常 SqlException - 已经处于事务状态，不支持并行事务。
     */
    public override func createTransaction(): Transaction {
        checkResource()

        OdbcTransaction(nativeApi, DBC_handlePtr, this)
    }

    /*
     * 关闭资源
     */
    public override func close(): Unit {
        if (isClosed()) {
            return
        }
        // 先断连再置关闭状态：断连失败时连接仍存活且句柄有效，抛出真实诊断供调用方重试
        var ret = nativeApi.sqlDisconnect(DBC_handlePtr)
        if (!SQLSucceeded(ret)) {
            throw nativeApi.diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
        }
        // 标记关闭必须先于句柄释放：释放后其他方法不得再访问句柄
        closed.store(true)
        nativeApi.sqlFreeHandle(SQL_HANDLE_DBC, DBC_handlePtr)
        nativeApi.sqlFreeHandle(SQL_HANDLE_ENV, ENV_handle)
    }

    /*
     * 判断资源是否关闭
     *
     * 返回值 Bool - 如果已经关闭返回true，否则返回false
     */
    public override func isClosed(): Bool {
        return closed.load()
    }

    private func checkResource() {
        if (isClosed()) {
            throw SqlException("The database Connection has been closed.")
        }
    }
}
