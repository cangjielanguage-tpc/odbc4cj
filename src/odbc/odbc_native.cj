/*
 * @Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights reserved.
 */
 
package odbc

/* data structure defined in unix odbc */
@C
foreign {
    func malloc(size: UIntNative): CPointer<Unit>
    func realloc(ptr: CPointer<Unit>, size: Int64): CPointer<Unit>
    func free(ptr: CPointer<Unit>): Unit

    /* Driver.openDb */
    func SQLAllocHandle(HandleType: Int16, InputHandle: CPointer<Unit>, OutputHandle: CPointer<CPointer<Unit>>): Int16
    func SQLFreeHandle(HandleType: Int16, Handle: CPointer<Unit>): Int16
    func SQLSetEnvAttr(ENV_handle: CPointer<Unit>, Attribute: Int32, Value: Int64, StringLength: Int32): Int16
    func SQLConnect(ConnectionHandle: CPointer<Unit>, ServerName: CString, NameLength1: Int16, UserName: CString,
                    NameLength2: Int16, Authentication: CString, NameLength3: Int16): Int16
    func SQLDriverConnect(ConnectionHandle: CPointer<Unit>, WindowHandle: CPointer<Unit>, InConnectionString: CString,
                          StringLength1: Int16, OutConnectionString: CString, BufferLength: Int16, StringLength2Ptr: CString,
                          DriverCompletion: Int16): Int16
    func SQLGetDiagRec(HandleType: Int16, Handle: CPointer<Unit>, RecNumber: Int16, Sqlstate: CPointer<Int8>,
                       NativeError: CPointer<Int32>, MessageText: CPointer<Int8>, BufferLength: Int16,
                       TextLength: CPointer<Int16>): Int16
    func SQLSetConnectAttr(DBC_handle: CPointer<Unit>, Attribute: Int32, Value: Int64, StringLength: Int32): Int16
    func SQLEndTran(HandleType: Int16, Handle: CPointer<Unit>, CompletionType: Int16): Int16
    func SQLExecDirect(STMT_handle: CPointer<Unit>, StatementText: CString, TextLength: Int64): Int16
    func SQLExecute(STMT_handle: CPointer<Unit>): Int16
    func SQLPrepare(STMT_handle: CPointer<Unit>, StatementText: CString, TextLength: Int64): Int16
    func SQLSetStmtAttr(STMT_handle: CPointer<Unit>, Attribute: Int32, Value: Int64, StringLength: Int32): Int16
    func SQLDescribeParam(STMT_handle: CPointer<Unit>, ParameterNumber: Int16, DataTypePtr: CPointer<Int16>,
                          ParameterSizePtr: CPointer<Int64>, DecimalDigitsPtr: CPointer<Int16>, NullablePtr: CPointer<Int16>): Int16
    func SQLNumParams(STMT_handle: CPointer<Unit>, ParameterCountPtr: CPointer<Int16>): Int16
    func SQLBindParameter(STMT_handle: CPointer<Unit>, ParameterNumber: Int64, InputOutputType: Int16,
                          ValueType: Int16, ParameterType: Int16, ColumnSize: UInt64, DecimalDigits: Int16,
                          ParameterValuePtr: CPointer<Unit>, BufferLength: Int64, StrLen_or_IndPtr: CPointer<Int64>): Int16
    func SQLNumResultCols(STMT_handle: CPointer<Unit>, ColumnCountPtr: CPointer<Int16>): Int16
    func SQLDescribeCol(STMT_handle: CPointer<Unit>, ColumnNumber: Int16, ColumnName: CString, BufferLength: Int16,
                        NameLengthPtr: CPointer<Int16>, DataTypePtr: CPointer<Int16>, ColumnSizePtr: CPointer<Int64>,
                        DecimalDigitsPtr: CPointer<Int16>, NullablePtr: CPointer<Int16>): Int16
    func SQLRowCount(STMT_handle: CPointer<Unit>, RowCountPtr: CPointer<Int64>): Int16
    func SQLFetch(STMT_handle: CPointer<Unit>): Int16
    func SQLBindCol(STMT_handle: CPointer<Unit>, ColumnNumber: Int64, TargetType: Int16,
                    TargetValuePtr: CPointer<Unit>, BufferLength: Int64, StrLen_or_IndPtr: CPointer<Int64>): Int16
    func SQLGetData(STMT_handle: CPointer<Unit>, Col_or_Param_Num: Int64, TargetType: Int16,
                    TargetValuePtr: CPointer<Unit>, BufferLength: Int64, StrLen_or_IndPtr: CPointer<Int64>): Int16
    func SQLCloseCursor(STMT_handle: CPointer<Unit>): Int16
    func SQLGetInfo(DBC_handle: CPointer<Unit>, InfoType: UInt16, InfoValuePtr: CPointer<Unit>, BufferLength: Int16,
                    StringLengthPtr: CPointer<Unit>): Int16
}
