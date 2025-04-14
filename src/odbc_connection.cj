/*
 * @Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights reserved.
 */
 
package odbc4cj

public class OdbcConnection <: Connection {
    private var DBC_handlePtr: CPointer<Unit>
    private let closed = AtomicBool(true)
    var objIdValue: UInt64
    /*
     * connection标识ID
     */
    public prop objId: UInt64 {
        get() {
            return objIdValue
        }
    }

    /*
     * 初始化数据库连接
     */
    init(DBC_handlePtr: CPointer<Unit>, dateBase: String, userName: String, password: String) {
        let rnd = Random(UInt64(DateTime.now().toUnixTimeStamp().toMilliseconds()))
        this.objIdValue = rnd.nextUInt64()
        var ret: Int16
        this.DBC_handlePtr = DBC_handlePtr
        /* Connect to database */
        unsafe {
            let csDateBase = LibC.mallocCString(dateBase)
            if (csDateBase.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let csUserName = LibC.mallocCString(userName)
            if (csUserName.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let csPassword = LibC.mallocCString(password)
            if (csPassword.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            ret = SQLConnect(DBC_handlePtr, csDateBase, SQL_NTS, csUserName, SQL_NTS, csPassword, SQL_NTS)
            if (DBC_handlePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            LibC.free(csDateBase)
            LibC.free(csUserName)
            LibC.free(csPassword)
        }
        if (!SQLSucceeded(ret)) {
            var exception = diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
            unsafe { SQLFreeHandle(SQL_HANDLE_DBC, DBC_handlePtr) }
            throw exception
        } else {
            closed.store(false)
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
            var infoValuePtr = LibC.malloc<Int8>(count: Int64(len))
            if (infoValuePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            if (DBC_handlePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            var ret = SQLGetInfo(DBC_handlePtr, infoType, CPointer<Unit>(infoValuePtr), len, CPointer<Unit>())
            if (!SQLSucceeded(ret)) {
                var exception = diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
                LibC.free(infoValuePtr)
                throw exception
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
    public override func prepareStatement(sql: String): OdbcStatement {
        /* Allocate statement handle */
        unsafe {
            var STMT_handlePtr: CPointer<CPointer<Unit>> = LibC.malloc<CPointer<Unit>>()
            if (STMT_handlePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            if (DBC_handlePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            var ret: Int16 = unsafe { SQLAllocHandle(SQL_HANDLE_STMT, DBC_handlePtr, STMT_handlePtr) }
            if (!SQLSucceeded(ret)) {
                var exception = diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
                unsafe { SQLFreeHandle(SQL_HANDLE_DBC, DBC_handlePtr) }
                throw exception
            }
            if (STMT_handlePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            if (DBC_handlePtr.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            var STMT_handlePtr1: CPointer<Unit> = STMT_handlePtr.read()
            if (STMT_handlePtr1.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            let csql = LibC.mallocCString(sql)
            if (csql.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            ret = SQLPrepare(STMT_handlePtr1, csql, csql.size())
            LibC.free(csql)
            if (!SQLSucceeded(ret)) {
                var exception = diagnoseException(SQL_HANDLE_DBC, DBC_handlePtr)
                throw exception
            }
            if (STMT_handlePtr1.isNull()) {
                throw SqlException("Native malloc Failed.")
            }
            var statement = OdbcStatement(STMT_handlePtr1, this)
            return statement
        }
    }

    /**
     * 创建事务对象
     * 异常 SqlException - 已经处于事务状态，不支持并行事务。
     */
    public override func createTransaction(): OdbcTransaction {
        if (DBC_handlePtr.isNull()) {
            throw SqlException("Native malloc Failed.")
        }
        OdbcTransaction(DBC_handlePtr, this)
    }

    /*
     * 关闭资源
     */
    public override func close(): Unit {
        if (isClosed()) {
            return
        }
        closed.store(true)
        unsafe {
		    SQLDisconnect(this.DBC_handlePtr)
            SQLFreeHandle(SQL_HANDLE_DBC, DBC_handlePtr)
        }
    }

    /*
     * 判断资源是否关闭
     *
     * 返回值 Bool - 如果已经关闭返回true，否则返回false
     */
    public override func isClosed(): Bool {
        return closed.load()
    }
}
