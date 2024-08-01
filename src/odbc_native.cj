/*
 * @Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights reserved.
 */
 
package odbc4cj

/* data structure defined in unix odbc */
@C
foreign {
    func malloc(size: UIntNative): CPointer<Unit>
    func realloc(ptr: CPointer<Unit>, size: Int64): CPointer<Unit>
    func free(ptr: CPointer<Unit>): Unit

    /* Driver.openDb */
    // 获取环境、连接、语句或描述符句柄
    func SQLAllocHandle(HandleType: Int16, InputHandle: CPointer<Unit>, OutputHandle: CPointer<CPointer<Unit>>): Int16
    // 释放环境、连接、语句或描述符句柄
    func SQLFreeHandle(HandleType: Int16, Handle: CPointer<Unit>): Int16
    // 设置环境属性
    func SQLSetEnvAttr(ENV_handle: CPointer<Unit>, Attribute: Int32, Value: Int64, StringLength: Int32): Int16
    // 按数据源名称、用户 ID 和密码连接到特定驱动程序
    func SQLConnect(ConnectionHandle: CPointer<Unit>, ServerName: CString, NameLength1: Int16, UserName: CString,
                    NameLength2: Int16, Authentication: CString, NameLength3: Int16): Int16
    // 	通过连接字符串或请求驱动程序管理器和驱动程序为用户显示连接对话框连接到特定驱动程序
    func SQLDriverConnect(ConnectionHandle: CPointer<Unit>, WindowHandle: CPointer<Unit>, InConnectionString: CString,
                          StringLength1: Int16, OutConnectionString: CString, BufferLength: Int16, StringLength2Ptr: CString,
                          DriverCompletion: Int16): Int16
    // (诊断数据结构的多个字段) 返回其他诊断信息
    func SQLGetDiagRec(HandleType: Int16, Handle: CPointer<Unit>, RecNumber: Int16, Sqlstate: CPointer<Int8>,
                       NativeError: CPointer<Int32>, MessageText: CPointer<Int8>, BufferLength: Int16,
                       TextLength: CPointer<Int16>): Int16
    // 设置连接属性
    func SQLSetConnectAttr(DBC_handle: CPointer<Unit>, Attribute: Int32, Value: Int64, StringLength: Int32): Int16
    // 提交或回滚事务
    func SQLEndTran(HandleType: Int16, Handle: CPointer<Unit>, CompletionType: Int16): Int16
    // 执行语句
    func SQLExecDirect(STMT_handle: CPointer<Unit>, StatementText: CString, TextLength: Int64): Int16
    // 执行已准备的语句
    func SQLExecute(STMT_handle: CPointer<Unit>): Int16
    // 准备 SQL 语句以供以后执行
    func SQLPrepare(STMT_handle: CPointer<Unit>, StatementText: CString, TextLength: Int64): Int16
    // 设置语句属性
    func SQLSetStmtAttr(STMT_handle: CPointer<Unit>, Attribute: Int32, Value: Int64, StringLength: Int32): Int16
    // 返回语句中特定参数的说明
    func SQLDescribeParam(STMT_handle: CPointer<Unit>, ParameterNumber: Int16, DataTypePtr: CPointer<Int16>,
                          ParameterSizePtr: CPointer<Int64>, DecimalDigitsPtr: CPointer<Int16>, NullablePtr: CPointer<Int16>): Int16
    // 返回语句中的参数数
    func SQLNumParams(STMT_handle: CPointer<Unit>, ParameterCountPtr: CPointer<Int16>): Int16
    // 为 SQL 语句中的参数分配存储
    func SQLBindParameter(STMT_handle: CPointer<Unit>, ParameterNumber: Int64, InputOutputType: Int16,
                          ValueType: Int16, ParameterType: Int16, ColumnSize: UInt64, DecimalDigits: Int16,
                          ParameterValuePtr: CPointer<Unit>, BufferLength: Int64, StrLen_or_IndPtr: CPointer<Int64>): Int16
    // 返回结果集中的列数
    func SQLNumResultCols(STMT_handle: CPointer<Unit>, ColumnCountPtr: CPointer<Int16>): Int16
    // 描述结果集中的列
    func SQLDescribeCol(STMT_handle: CPointer<Unit>, ColumnNumber: Int16, ColumnName: CString, BufferLength: Int16,
                        NameLengthPtr: CPointer<Int16>, DataTypePtr: CPointer<Int16>, ColumnSizePtr: CPointer<Int64>,
                        DecimalDigitsPtr: CPointer<Int16>, NullablePtr: CPointer<Int16>): Int16
    // 返回受插入、更新或删除请求影响的行数
    func SQLRowCount(STMT_handle: CPointer<Unit>, RowCountPtr: CPointer<Int64>): Int16
    // 返回多个结果行
    func SQLFetch(STMT_handle: CPointer<Unit>): Int16
    // 为结果列分配存储并指定数据类型
    func SQLBindCol(STMT_handle: CPointer<Unit>, ColumnNumber: Int64, TargetType: Int16,
                    TargetValuePtr: CPointer<Unit>, BufferLength: Int64, StrLen_or_IndPtr: CPointer<Int64>): Int16
    // 返回结果集一行的一列的一部分或全部。 (适用于长数据值。)
    func SQLGetData(STMT_handle: CPointer<Unit>, Col_or_Param_Num: Int64, TargetType: Int16,
                    TargetValuePtr: CPointer<Unit>, BufferLength: Int64, StrLen_or_IndPtr: CPointer<Int64>): Int16
    // 关闭已在语句句柄上打开的游标
    func SQLCloseCursor(STMT_handle: CPointer<Unit>): Int16
    // 返回有关特定驱动程序和数据源的信息
    func SQLGetInfo(DBC_handle: CPointer<Unit>, InfoType: UInt16, InfoValuePtr: CPointer<Unit>, BufferLength: Int16,
                    StringLengthPtr: CPointer<Unit>): Int16
    // 关闭与特定连接句柄关联的连接
    func SQLDisconnect(ConnectionHandle: CPointer<Unit>): Int16
}
