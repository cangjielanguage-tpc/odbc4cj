package odbc

public class OdbcDatasource <: Datasource {
    private var dateBase: String
    private var userName: String
    private var password: String
    private var DBC_handlePtr = CPointer<CPointer<Unit>>()

    /*
     * 初始化数据源
     */
    init(ENV_handle: CPointer<Unit>, dateBase: String, userName: String, password: String, opts: Array<(String, String)>) {
        var ret: Int16
        this.dateBase = dateBase
        this.userName = userName
        this.password = password
        DBC_handlePtr = LibC.malloc<CPointer<Unit>>()
        if (DBC_handlePtr.isNull()) {
            throw SqlException("Native malloc Failed.")
        }
        var res = unsafe { SQLAllocHandle(SQL_HANDLE_DBC, ENV_handle, DBC_handlePtr) }
        if (!SQLSucceeded(res)) {
            var exception = diagnoseException(SQL_HANDLE_ENV, ENV_handle)
            unsafe { SQLFreeHandle(SQL_HANDLE_ENV, ENV_handle) }
            throw exception
        }
        for (i in 0..opts.size) {
            if (opts[i][0] == "SQL_ATTR_AUTOCOMMIT") {
                if (opts[i][1] == "SQL_AUTOCOMMIT_OFF") {
                    /* Set autocommit attribute */
                    ret = unsafe { SQLSetConnectAttr(DBC_handlePtr.read(), SQL_ATTR_AUTOCOMMIT, SQL_AUTOCOMMIT_OFF, SQL_IS_UINTEGER) }
                    if (!SQLSucceeded(ret)) {
                        unsafe { diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr.read()) }
                    }
                } else if (opts[i][1] != "SQL_AUTOCOMMIT_ON") {
                    throw SqlException("SQL_ATTR_AUTOCOMMIT value must be SQL_AUTOCOMMIT_OFF or SQL_AUTOCOMMIT_ON")
                }
            } else {
                throw SqlException("Only supported SQL_ATTR_AUTOCOMMIT.")
            }
        }
    }

    /*
     * 设置连接选项 (使用 setOption(key: Int32, value: Int64))
     */
    public override func setOption(key: String, value: String): Unit {
    }

    /*
     * 设置连接选项
     */
    public func setOption(key: Int32, value: Int64): Unit {
        var ret = unsafe { SQLSetConnectAttr(DBC_handlePtr.read(), key, value, SQL_IS_INTEGER) }
        if (!SQLSucceeded(ret)) {
            unsafe { diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr.read()) }
        }
    }

    /*
     * 返回一个可用的连接
     * 返回值 Connection - 数据库连接实例
     */
    public override func connect(): OdbcConnection {
        var conn = unsafe { OdbcConnection(DBC_handlePtr.read(), dateBase, userName, password) }
        return conn
    }

    public override func close(): Unit {
    }

    public override func isClosed(): Bool {
        return false
    }
}
