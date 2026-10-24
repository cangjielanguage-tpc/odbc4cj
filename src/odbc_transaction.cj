package odbc4cj

public class OdbcTransaction <: Transaction {
    private let nativeApi: OdbcNativeApi
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
            var infoValuePtr = nativeApi.malloc(LEN_MALLOC_4)
            if (infoValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            var strLenPtr = CPointer<Int32>(nativeApi.malloc(LEN_MALLOC_4))
            if (strLenPtr.isNull()) {
                nativeApi.free(infoValuePtr)
                throw SqlException("Native malloc Failed.")
            }
            unsafe { CPointer<UInt32>(infoValuePtr).write(0) }
            // 当前生效的隔离级别必须用 SQLGetConnectAttr(SQL_ATTR_TXN_ISOLATION) 读取（与 setter 写入同一属性）；
            // 原实现误用 SQLGetInfo(SQL_TXN_ISOLATION_OPTION)，那是驱动“支持”的级别集合而非当前值
            var ret = nativeApi.sqlGetConnectAttr(DBC_handlePtr, SQL_ATTR_TXN_ISOLATION, infoValuePtr,
                Int32(LEN_MALLOC_4), strLenPtr)
            if (!SQLSucceeded(ret)) {
                nativeApi.free(infoValuePtr)
                nativeApi.free(CPointer<Unit>(strLenPtr))
                throw nativeApi.diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
            }
            var infoValue = unsafe { CPointer<UInt32>(infoValuePtr).read() }
            nativeApi.free(infoValuePtr)
            nativeApi.free(CPointer<Unit>(strLenPtr))

            // 返回值为隔离级别位掩码，按位匹配（个别驱动可能返回组合位）
            if ((infoValue & SQL_TXN_SERIALIZABLE) != 0) {
                level = Serializable
            } else if ((infoValue & SQL_TXN_REPEATABLE_READ) != 0) {
                level = RepeatableRead
            } else if ((infoValue & SQL_TXN_READ_COMMITTED) != 0) {
                level = ReadCommitted
            } else if ((infoValue & SQL_TXN_READ_UNCOMMITTED) != 0) {
                level = ReadUncommitted
            } else {
                level = ReadCommitted
            }
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
                case Unspecified => valuePtr = Int64(SQL_TXN_READ_COMMITTED)
                case _ => throw SqlException(" ${value} mode not supported.")
            }
            var ret0 = nativeApi.sqlEndTran(SQL_HANDLE_DBC, DBC_handlePtr, SQL_COMMIT)
            if (!SQLSucceeded(ret0)) {
                throw nativeApi.diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
            }
            var ret = nativeApi.sqlSetConnectAttr(DBC_handlePtr, SQL_ATTR_TXN_ISOLATION, valuePtr, SQL_IS_UINTEGER)
            if (!SQLSucceeded(ret)) {
                throw nativeApi.diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
            }

            level = value
        }
    }

    /*
     * 数据库事务访问模式。
     */
    public mut override prop accessMode: TransactionAccessMode {
        get() {
            myAccessMode
        }
        set(value) {
            if (odbcConnection.isClosed()) {
                throw SqlException("The database connection has been closed")
            }
            if (value != myAccessMode) {
                let valuePtr = match (value) {
                    case ReadWrite => SQL_MODE_READ_WRITE
                    case ReadOnly => SQL_MODE_READ_ONLY
                    case Unspecified => SQL_MODE_READ_WRITE
                    case _ => throw UnsupportedException()
                }
                var ret = nativeApi.sqlSetConnectAttr(DBC_handlePtr, SQL_ATTR_ACCESS_MODE, valuePtr, SQL_IS_UINTEGER)
                if (!SQLSucceeded(ret)) {
                    throw nativeApi.diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
                }
                myAccessMode = value
            }
        }
    }

    /*
     * 数据库事务延迟模式。(不支持)
     */
    public mut override prop deferrableMode: TransactionDeferrableMode {
        get() {
            throw UnsupportedException()
        }
        set(_) {
            throw UnsupportedException()
        }
    }

    init(nativeApi: OdbcNativeApi, DBC_handlePtr: CPointer<Unit>, odbcConnection: OdbcConnection) {
        this.nativeApi = nativeApi
        if (odbcConnection.isClosed()) {
            throw SqlException("The database connection has been closed")
        }
        this.DBC_handlePtr = DBC_handlePtr
        this.odbcConnection = odbcConnection
    }

    /*
     * 开始数据库事务（关闭自动提交）。
     * 异常 SqlException - 开启事务时服务器端发生错误。
     * 异常 SqlException - 连接已关闭。
     */
    public override func begin(): Unit {
        if (odbcConnection.isClosed()) {
            throw SqlException("The database connection has been closed")
        }
        /* Set autocommit attribute */
        var ret = nativeApi.sqlSetConnectAttr(DBC_handlePtr, SQL_ATTR_AUTOCOMMIT, SQL_AUTOCOMMIT_OFF, SQL_IS_UINTEGER)
        if (!SQLSucceeded(ret)) {
            throw nativeApi.diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
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
        var ret = nativeApi.sqlEndTran(SQL_HANDLE_DBC, DBC_handlePtr, SQL_COMMIT)
        if (!SQLSucceeded(ret)) {
             throw nativeApi.diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
        }
        //恢复AUTOCOMMIT - 事务结束回到自动提交模式
        nativeApi.sqlSetConnectAttr(DBC_handlePtr, SQL_ATTR_AUTOCOMMIT, SQL_AUTOCOMMIT_ON, SQL_IS_UINTEGER)
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
        var ret = nativeApi.sqlEndTran(SQL_HANDLE_DBC, DBC_handlePtr, SQL_ROLLBACK)
        if (!SQLSucceeded(ret)) {
             throw nativeApi.diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
        }
        //恢复AUTOCOMMIT - 事务结束回到自动提交模式
        nativeApi.sqlSetConnectAttr(DBC_handlePtr, SQL_ATTR_AUTOCOMMIT, SQL_AUTOCOMMIT_ON, SQL_IS_UINTEGER)
    }

    /*
     * 在事务中创建一个指定名称的保存点，可用于回滚事务的一部分。(不支持)
     * 异常 UnsupportedException - ODBC 不支持保存点。
     */
    public override func save(savePointName: String): Unit {
        throw UnsupportedException("ODBC does not support savepoints")
    }

    /*
     * 回滚事务至指定保存点名称。(不支持)
     * 异常 UnsupportedException - ODBC 不支持保存点。
     */
    public override func rollback(savePointName: String): Unit {
        throw UnsupportedException("ODBC does not support savepoints")
    }

    /*
     * 销毁先前在当前事务中定义的保存点。这允许系统在事务结束之前回收一些资源。(不支持)
     * 异常 UnsupportedException - ODBC 不支持保存点。
     */
    public override func release(savePointName: String): Unit {
        throw UnsupportedException("ODBC does not support savepoints")
    }
}
