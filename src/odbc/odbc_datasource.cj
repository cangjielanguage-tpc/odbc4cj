/*
 * @Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights reserved.
 */
 
package odbc

public class OdbcDatasource <: Datasource {
    private var dateBase: String
    private var userName: String
    private var password: String
    private var opts: Array<(String, String)>
    /*
     * 初始化数据源
     */
    init(dateBase: String, userName: String, password: String, opts: Array<(String, String)>) {
        this.dateBase = dateBase
        this.userName = userName
        this.password = password
        this.opts = opts
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
    }

    /*
     * 返回一个可用的连接
     * 返回值 Connection - 数据库连接实例
     */
    public override func connect(): OdbcConnection {
        unsafe {
            var ENV_handlePtr: CPointer<CPointer<Unit>> = LibC.malloc<CPointer<Unit>>()
            if (ENV_handlePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let nullHandle = CPointer<Unit>()
            var ret0 = unsafe { SQLAllocHandle(SQL_HANDLE_ENV, nullHandle, ENV_handlePtr) }
            if (!SQLSucceeded(ret0)) {
                throw SqlException("Can't initialize module odbc. SQLAllocEnv failed.")
            }
            /* Set version attribute */
            
            ret0 = unsafe { SQLSetEnvAttr(ENV_handlePtr.read(), SQL_ATTR_ODBC_VERSION, SQL_OV_ODBC3, SQL_IS_INTEGER) }
            if (!SQLSucceeded(ret0)) {
                throw SqlException("Unable to set SQL_ATTR_ODBC_VERSION attribute.")
            }
            var ENV_handle: CPointer<Unit> = ENV_handlePtr.read()

            var DBC_handlePtr = CPointer<CPointer<Unit>>()
            var ret: Int16
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
            var conn =  OdbcConnection(DBC_handlePtr.read(), dateBase, userName, password) 
            return conn
        }
    }

    public override func close(): Unit {
    }

    public override func isClosed(): Bool {
        return false
    }
}
