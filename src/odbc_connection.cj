package odbc4cj

public open class OdbcConnection <: Connection {
    private let nativeApi: OdbcNativeApi
    private var ENV_handle: CPointer<Unit>
    private var DBC_handlePtr: CPointer<Unit>
    private let closed = AtomicBool(true)
    private var options: HashMap<String, String>

    /**
     * 初始化数据库连接
     * 通过HashMap 选项连接ODBC 数据源
     */
    init(nativeApi: OdbcNativeApi, options: HashMap<String, String>) {
        this.nativeApi = nativeApi
        this.options = options
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
     * 返回连接到的数据源元数据 (不支持), 使用 getInfo 方法
     */
    public override func getMetaData(): Map<String, String> {
        checkResource()
        var meta = HashMap<String, String>()
        meta["driver.name"] = getInfoString(SQL_DRIVER_NAME)
        meta["driver.version"] = getInfoString(SQL_DRIVER_VER)
        meta["dbms.name"] = getInfoString(SQL_DBMS_NAME)
        meta["dbms.version"] = getInfoString(SQL_DBMS_VER)
        meta["server.name"] = getInfoString(SQL_SERVER_NAME)
        meta["data.source.name"] = getInfoString(SQL_DATA_SOURCE_NAME)
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

        var ret = nativeApi.sqlGetInfo(DBC_handlePtr, infoType, CPointer<Unit>(infoValuePtr), bufferLen,
            CPointer<Int16>())
        if (!SQLSucceeded(ret)) {
            unsafe { LibC.free(infoValuePtr) }
            return ""
        }

        var result = CString(CPointer<UInt8>(infoValuePtr)).toString()

        unsafe { LibC.free(infoValuePtr) }

        return result
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
            var exception = nativeApi.diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
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
        closed.store(true)
        nativeApi.sqlDisconnect(DBC_handlePtr)

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
