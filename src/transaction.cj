/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2023-2023. All rights reserved.
 */

package odbc

public class OdbcTransaction <: Transaction {
    private var DBC_handlePtr: CPointer<Unit>
    public var level: TransactionIsoLevel = Default
    public var myAccessMode: TransactionAccessMode = ReadWrite
    public var myDeferrableMode: TransactionDeferrableMode = NotDeferrable

    /*
     * 数据库事务隔离级别。
     */
    public mut prop isoLevel: TransactionIsoLevel {
        get() {
            level
        }

        set(value) {
            level = value
        }
    }

    /*
     * 数据库事务访问模式。
     */
    public mut prop accessMode: TransactionAccessMode {
        get() {
            myAccessMode
        }

        set(value) {
            myAccessMode = value
        }
    }

    /*
     * 数据库事务延迟模式。
     */
    public mut prop deferrableMode: TransactionDeferrableMode {
        get() {
            myDeferrableMode
        }

        set(value) {
            myDeferrableMode = value
        }
    }

    public init(DBC_handlePtr: CPointer<Unit>) {
        this.DBC_handlePtr = DBC_handlePtr
    }

    /*
     * 开始数据库事务。
     * 异常 SqlException - 提交事务时服务器端发生错误。
     * 异常 SqlException - 事务已提交或回滚或连接已断开。
     */
    public func begin(): Unit {
        /* Set autocommit attribute */
        var ret = unsafe { SQLSetConnectAttr(DBC_handlePtr, SQL_ATTR_AUTOCOMMIT, SQL_AUTOCOMMIT_OFF, SQL_IS_UINTEGER) }
        if (!SQLSucceeded(ret)) {
            unsafe { DiagnoseException(SQL_HANDLE_DBC, DBC_handlePtr) }
        }
    }

    /*
     * 提交数据库事务。
     * 异常 SqlException - 提交事务时服务器端发生错误。
     * 异常 SqlException - 事务已提交或回滚或连接已断开。
     */
    public func commit(): Unit {
        var ret = unsafe { SQLEndTran(SQL_HANDLE_DBC, DBC_handlePtr, SQL_COMMIT) }
        if (!SQLSucceeded(ret)) {
            unsafe { DiagnoseException(SQL_HANDLE_DBC, DBC_handlePtr) }
        }
    }

    /*
     * 从挂起状态回滚事务。
     * 异常 SqlException - 回滚事务时服务器端发生错误。
     * 异常 SqlException - 事务已提交或回滚或连接已断开。
     */
    public func rollback(): Unit {
    }

    /*
     * 在事务中创建一个指定名称的保存点，可用于回滚事务的一部分。
     * 异常 SqlException - 提交事务时服务器端发生错误。
     * 异常 SqlException - 事务已提交或回滚或连接已断开。
     */
    public func save(savePointName: String): Unit {

    }

    /*
     * 回滚事务至指定保存点名称。
     * 异常 SqlException - 提交事务时服务器端发生错误。
     * 异常 SqlException - 事务已提交或回滚或连接已断开。
     */
    public func rollback(savepointName: String): Unit {

    }

    /*
     * 销毁先前在当前事务中定义的保存点。这允许系统在事务结束之前回收一些资源。
     * 异常 SqlException - 提交事务时服务器端发生错误。
     * 异常 SqlException - 事务已提交或回滚或连接已断开。
     */
    public func release(savePointName: String): Unit {

    }
}