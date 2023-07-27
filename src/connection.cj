/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
 */

package odbc

from std import collection.*, sync.*

public class OdbcConnection <: Connection {
    private var DBC_handlePtr: CPointer<Unit>
    private let closed = AtomicBool(true)
    private var STMT_handlePtr: CPointer<CPointer<Unit>>

    public init(DBC_handlePtr: CPointer<Unit>, dateBase: String, userName: String, password: String) {
        var ret: Int16

        this.DBC_handlePtr = DBC_handlePtr

        /* Connect to database */
        unsafe {
            let csDateBase = LibC.mallocCString(dateBase)
            let csUserName = LibC.mallocCString(userName)
            let csPassword = LibC.mallocCString(password)
            ret = SQLConnect(DBC_handlePtr, csDateBase, SQL_NTS, csUserName, SQL_NTS, csPassword, SQL_NTS)
            LibC.free(csDateBase)
            LibC.free(csUserName)
            LibC.free(csPassword)
        }

        if (!SQLSucceeded(ret)) {
            unsafe {
                DiagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
                SQLFreeHandle(SQL_HANDLE_DBC, DBC_handlePtr)
            }
            throw SqlException("Can't initialize module odbc. SQLDriverConnect failed.")
        } else {
            closed.store(false)
        }

        STMT_handlePtr = CPointer<CPointer<Unit>>(unsafe { malloc(8) })
        if (STMT_handlePtr.isNull()) {
            throw SqlException("native malloc Failed.")
        }
        ret = unsafe { SQLAllocHandle(SQL_HANDLE_STMT, DBC_handlePtr, STMT_handlePtr) }
        if (!SQLSucceeded(ret)) {
            unsafe {
                DiagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
                SQLFreeHandle(SQL_HANDLE_DBC, DBC_handlePtr)
                throw SqlException("Can't initialize module odbc. SQLAllocStmt failed.")
            }
        }
    }

    /**
     * 描述与数据源连接的当前状态
     */
    public prop state: ConnectionState {
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
    public func getMetaData(): Map<String, String> {
        HashMap<String, String>()
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
    public func getInfo(infoType: UInt16, len: Int16): String {
        var infoValue: String = ""

        if (!(len == 2 || len == 4 || len >= 8)) {
            throw SqlException("len is not 2, 4 or >=8.")
        }
        unsafe {
            var infoValuePtr = malloc(UIntNative(len))
            if (infoValuePtr.isNull()) {
                throw SqlException("native malloc Failed.")
            }
            var ret = SQLGetInfo(DBC_handlePtr, infoType, infoValuePtr, len, CPointer<Unit>())
            if (!SQLSucceeded(ret)) {
                DiagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
                free(infoValuePtr)
                throw SqlException("SQLGetInfo failed.")
            }
            if (len == 2) {
                infoValue = CPointer<UInt16>(infoValuePtr).read().toString()
            } else if (len == 4) {
                infoValue = CPointer<UInt32>(infoValuePtr).read().toString()
            } else if (len == 8) {
                infoValue = CPointer<UInt64>(infoValuePtr).read().toString()
            } else if (len > 8) {
                infoValue = CString(CPointer<UInt8>(infoValuePtr)).toString()
            }

            free(infoValuePtr)
        }

        return infoValue
    }

    /**
     * 通过传入的 sql 语句，返回一个预执行的 Statement 对象实例
     * 参数 sql - 预执行的 sql 语句，sql 语句的参数只支持 ? 符号占位符
     * 返回值 Statement - 一个可以执行 sql 语句的实例对象
     * 异常 SqlException - 语法错误，sql 语句包含不认识的字符
     */
    public func prepareStatement(sql: String): OdbcStatement {
        /* Allocate statement handle */
        unsafe {
            var statement = OdbcStatement(STMT_handlePtr.read())
            let csql = LibC.mallocCString(sql)
            var ret = SQLPrepare(STMT_handlePtr.read(), csql, csql.size())
            LibC.free(csql)
            if (!SQLSucceeded(ret)) {
                DiagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
            }
            return statement
        }
    }

    /**
     * 创建事务对象
     * 异常 SqlException - 已经处于事务状态，不支持并行事务。
     */
    public func createTransaction(): OdbcTransaction {
        OdbcTransaction(DBC_handlePtr)
    }

    public func close(): Unit {
        if (closed.load()) {
            return
        }
        closed.store(true)
        unsafe {
            DiagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
            SQLFreeHandle(SQL_HANDLE_DBC, DBC_handlePtr)
        }
    }

    public func isClosed(): Bool {
        return closed.load()
    }
}
