/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
 */

package odbc

from std import database.sql.*, io.*, time.*, regex.*, core.*, math.*

public class OdbcDriver <: Driver {
    private var ENV_handlePtr: CPointer<CPointer<Unit>>

    public init() {
        /* Allocate Environment Handle */
        this.ENV_handlePtr = CPointer<CPointer<Unit>>(unsafe { malloc(LEN_MALLOC_8) })
        if (this.ENV_handlePtr.isNull()) {
            throw SqlException("Native malloc Failed.")
        }
        let nullHandle = CPointer<Unit>()
        var ret = unsafe { SQLAllocHandle(SQL_HANDLE_ENV, nullHandle, this.ENV_handlePtr) }
        if (!SQLSucceeded(ret)) {
            throw SqlException("Can't initialize module odbc. SQLAllocEnv failed.")
        }

        /* Set version attribute */
        ret = unsafe { SQLSetEnvAttr(this.ENV_handlePtr.read(), SQL_ATTR_ODBC_VERSION, SQL_OV_ODBC3, SQL_IS_INTEGER) }
        if (!SQLSucceeded(ret)) {
            throw SqlException("Unable to set SQL_ATTR_ODBC_VERSION attribute.")
        }
    }

    /**
     * 驱动名称 (不支持)
     */
    public prop name: String {
        get() {
            ""
        }
    }

    /**
     * 驱动版本 (不支持)
     */
    public prop version: String {
        get() {
            ""
        }
    }

    /**
     * 指示驱动程序是否与连接池亲和。(不支持)
     * 如果否，则不建议使用连接池。
     * 比如 sqlite 驱动连接池化的收益不明显不建议使用连接池
     */
    public prop preferredPooling: Bool {
        get() {
            true
        }
    }

    /**
     * 通过 connectionString 和选项打开数据源
     * 参数 connectionString - 数据库连接字符串, 格式为 "DATABASE=sql;UID=abc;PWD=123"
     * 参数 opts - key, value 的 tuple 数组，打开数据源的选项
     *            opts 只有 ("SQL_ATTR_AUTOCOMMIT", "SQL_AUTOCOMMIT_OFF") 和 ("SQL_ATTR_AUTOCOMMIT", "SQL_AUTOCOMMIT_ON")
     *            2个选项，用来设置 sql 语句提交方式
     * 返回值 Datasource - 数据源实例
     */
    public func open(connectionString: String, opts: Array<(String, String)>): OdbcDatasource {
        var dateBase = ""
        var userName = ""
        var pd = ""

        var arr = connectionString.split(';')
        if (arr.size != 3) {
            throw SqlException("Url is error")
        }

        for (i in 0..3) {
            var list = arr[i].split('=')
            if (list.size != 2) {
                throw SqlException("Url is error")
            }

            if (list[0].equals("DATABASE")) {
                dateBase = list[1]
            } else if (list[0].equals("UID")) {
                userName = list[1]
            } else if (list[0].equals("PWD")) {
                pd = list[1]
            } else {
                throw SqlException("Url is error")
            }
        }

        return unsafe { OdbcDatasource(ENV_handlePtr.read(), dateBase, userName, pd, opts) }
    }
}
