/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
 */

package odbc

from std import collection.*

public class OdbcConnection <: Connection {
    private var DBC_handlePtr: CPointer<Unit>

    public init(DBC_handlePtr: CPointer<Unit>, serverName: String, userName: String, authentication: String) {
        var ret: Int16

        this.DBC_handlePtr = DBC_handlePtr

        /* Connect to database */
        unsafe {
            let csServerName = LibC.mallocCString(serverName)
            let csUserName = LibC.mallocCString(userName)
            let csAuthentication = LibC.mallocCString(authentication)
            ret = SQLConnect(DBC_handlePtr, csServerName, SQL_NTS, csUserName, SQL_NTS, csAuthentication, SQL_NTS)
            LibC.free(csServerName)
            LibC.free(csUserName)
            LibC.free(csAuthentication)
        }

        if (!SQLSucceeded(ret)) {
            unsafe {
                DiagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
                // SQLFreeHandle(SQL_HANDLE_ENV, ENV_handle)
                // SQLFreeHandle(SQL_HANDLE_DBC, DBC_handlePtr)
            }
            throw SqlException("Can't initialize module odbc. SQLDriverConnect failed.")
        }
    }

    /**
     * 描述与数据源连接的当前状态
     */
    public prop state: ConnectionState {
        get() {
            if (DBC_handlePtr.isNull()) {
                Closed
            } else {
                Connected
            }
        }
    }

    /**
     * 返回连接到的数据源元数据
     */
    public func getMetaData(): Map<String, String> {
        HashMap<String, String>()
    }

    /**
     * 通过传入的 sql 语句，返回一个预执行的 Statement 对象实例
     * 参数 sql - 预执行的 sql 语句，sql 语句的参数只支持 ? 符号占位符
     * 返回值 Statement - 一个可以执行 sql 语句的实例对象
     * 异常 SqlException - 语法错误，sql 语句包含不认识的字符
     */
    public func prepareStatement(sql: String): OdbcStatement {
        /* Allocate statement handle */
        var statement = OdbcStatement(DBC_handlePtr)
        unsafe {
            let csql = LibC.mallocCString(sql)
            var ret = SQLPrepare(statement.getStmtHandle(), csql, csql.size())
            LibC.free(csql)
            if (!SQLSucceeded(ret)) {
                unsafe { DiagnoseException(SQL_HANDLE_DBC, DBC_handlePtr) }
            }
        }

        return statement
    }

    /**
     * 创建事务对象
     * 异常 SqlException - 已经处于事务状态，不支持并行事务。
     */
    public func createTransaction(): OdbcTransaction {
        OdbcTransaction(DBC_handlePtr)
    }

    public func getDbcHandle(): CPointer<Unit> {
        return DBC_handlePtr
    }

    public func close(): Unit {
        unsafe { SQLFreeHandle(SQL_HANDLE_DBC, DBC_handlePtr) }
    }

    public func isClosed(): Bool {
        return DBC_handlePtr.isNull()
    }
}
