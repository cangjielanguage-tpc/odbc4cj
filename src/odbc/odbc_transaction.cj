/*
 * @Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights reserved.
 */
 
package odbc

public class OdbcTransaction <: Transaction {
    private var DBC_handlePtr: CPointer<Unit>
    public var level: TransactionIsoLevel = Unspecified
    public var myAccessMode: TransactionAccessMode = ReadWrite
    public var myDeferrableMode: TransactionDeferrableMode = NotDeferrable
    var odbcConnection: OdbcConnection

    /*
     * 数据库事务隔离级别。
     */
    public mut override prop isoLevel: TransactionIsoLevel {
        get() {
            level
        }

        set(value) {
            if (odbcConnection.isClosed()) {
                throw SqlException("The database connection has been closed")
            }
            var valuePtr: Int64
            match (value) {
                case ReadCommitted => valuePtr = Int64(SQL_TXN_READ_COMMITTED)
                case ReadUncommitted => valuePtr = Int64(SQL_TXN_READ_UNCOMMITTED)
                case RepeatableRead => valuePtr = Int64(SQL_TXN_REPEATABLE_READ)
                case Serializable => valuePtr = Int64(SQL_TXN_SERIALIZABLE)
                case Unspecified => valuePtr = Int64(SQL_TXN_REPEATABLE_READ)
                case _ => throw SqlException(" ${value} mode not supported.")
            }
            var ret = unsafe { SQLSetConnectAttr(DBC_handlePtr, SQL_ATTR_TXN_ISOLATION, valuePtr, SQL_IS_UINTEGER) }
            if (!SQLSucceeded(ret)) {
                var exception = diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
                throw exception
            }

            level = value
        }
    }

    /*
     * 数据库事务访问模式。(不支持)
     */
    public mut override prop accessMode: TransactionAccessMode {
        get() {
            myAccessMode
        }

        set(value) {
            myAccessMode = value
        }
    }

    /*
     * 数据库事务延迟模式。(不支持)
     */
    public mut override prop deferrableMode: TransactionDeferrableMode {
        get() {
            myDeferrableMode
        }

        set(value) {
            myDeferrableMode = value
        }
    }

    init(DBC_handlePtr: CPointer<Unit>, odbcConnection: OdbcConnection) {
        if (odbcConnection.isClosed()) {
            throw SqlException("The database connection has been closed")
        }
        this.DBC_handlePtr = DBC_handlePtr
        this.odbcConnection = odbcConnection
        var infoValue: UInt32
        unsafe {
            var infoValuePtr = malloc(LEN_MALLOC_4)
            if (infoValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            var ret = SQLGetInfo(DBC_handlePtr, SQL_TXN_ISOLATION_OPTION, infoValuePtr, 4, CPointer<Unit>())
            if (!SQLSucceeded(ret)) {
                var exception = diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
                free(infoValuePtr)
                throw exception
            }
            infoValue = CPointer<UInt32>(infoValuePtr).read()
            free(infoValuePtr)
        }

        if (infoValue == SQL_TXN_READ_UNCOMMITTED) {
            level = ReadUncommitted
        } else if (infoValue == SQL_TXN_READ_COMMITTED) {
            level = ReadCommitted
        } else if (infoValue == SQL_TXN_REPEATABLE_READ) {
            level = RepeatableRead
        } else if (infoValue == SQL_TXN_SERIALIZABLE) {
            level = Serializable
        }
    }

    /*
     * 开始数据库事务。
     * 异常 SqlException - 提交事务时服务器端发生错误。
     * 异常 SqlException - 事务已提交或回滚或连接已断开。
     */
    public override func begin(): Unit {
        if (odbcConnection.isClosed()) {
            throw SqlException("The database connection has been closed")
        }
        /* Set autocommit attribute */
        var ret = unsafe { SQLSetConnectAttr(DBC_handlePtr, SQL_ATTR_AUTOCOMMIT, SQL_AUTOCOMMIT_OFF, SQL_IS_UINTEGER) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
            throw exception
        }
    }

    /*
     * 提交数据库事务。
     * 异常 SqlException - 提交事务时服务器端发生错误。
     * 异常 SqlException - 事务已提交或回滚或连接已断开。
     */
    public override func commit(): Unit {
        if (odbcConnection.isClosed()) {
            throw SqlException("The database connection has been closed")
        }
        var ret = unsafe { SQLEndTran(SQL_HANDLE_DBC, DBC_handlePtr, SQL_COMMIT) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
            throw exception
        }
    }

    /*
     * 从挂起状态回滚事务。
     * 异常 SqlException - 回滚事务时服务器端发生错误。
     * 异常 SqlException - 事务已提交或回滚或连接已断开。
     */
    public override func rollback(): Unit {
        if (odbcConnection.isClosed()) {
            throw SqlException("The database connection has been closed")
        }
        var ret = unsafe { SQLEndTran(SQL_HANDLE_DBC, DBC_handlePtr, SQL_ROLLBACK) }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
            throw exception
        }
    }

    /*
     * 在事务中创建一个指定名称的保存点，可用于回滚事务的一部分。(不支持)
     * 异常 SqlException - 提交事务时服务器端发生错误。
     * 异常 SqlException - 事务已提交或回滚或连接已断开。
     */
    public override func save(savePointName: String): Unit {
    }

    /*
     * 回滚事务至指定保存点名称。(不支持)
     * 异常 SqlException - 提交事务时服务器端发生错误。
     * 异常 SqlException - 事务已提交或回滚或连接已断开。
     */
    public override func rollback(savePointName: String): Unit {
    }

    /*
     * 销毁先前在当前事务中定义的保存点。这允许系统在事务结束之前回收一些资源。(不支持)
     * 异常 SqlException - 提交事务时服务器端发生错误。
     * 异常 SqlException - 事务已提交或回滚或连接已断开。
     */
    public override func release(savePointName: String): Unit {
    }
}