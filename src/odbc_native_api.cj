package odbc4cj

public interface OdbcNativeApi {
    //Handle management
    func sqlAllocHandle(handleType: Int16, inputHandle: CPointer<Unit>, outputHandle: CPointer<CPointer<Unit>>): Int16
    func sqlFreeHandle(handleType: Int16, handle: CPointer<Unit>): Unit

    //Environment
    func sqlSetEnvAttr(envHandle: CPointer<Unit>, attribute: Int32, value: Int64, stringLength: Int32): Int16
    
    //Connection
    func sqlDriverConnect(connectionHandle: CPointer<Unit>, windowHandle: CPointer<Unit>,
                          inConnectionString: CString,stringLength1: Int16, 
                          outConnectionString: CPointer<UInt8>, bufferLength: Int16,
                          stringLength2Ptr: CPointer<Int16>, driverCompletion: UInt16): Int16
    func sqlDisconnect(connectionHandle: CPointer<Unit>): Unit

    func sqlGetDiagRec(handleType: Int16, handle: CPointer<Unit>, recNumber: Int16, sqlState: CPointer<Int8>,
        nativeError: CPointer<Int32>, messageText: CPointer<Int8>, bufferLength: Int16, textLength: CPointer<Int16>): Int16
    func sqlSetConnectAttr(dbcHandle: CPointer<Unit>, attribute: Int32, value: Int64, stringLength: Int32): Int16
    func sqlEndTran(handleType: Int16, handle: CPointer<Unit>, completionType: Int16): Int16
    func sqlExecDirect(stmtHandle: CPointer<Unit>, statementText: CString, textLength: Int32): Int16
    func sqlExecute(stmtHandle: CPointer<Unit>): Int16
    func sqlPrepare(stmtHandle: CPointer<Unit>, statementText: CString, textLength: Int32): Int16
    func sqlSetStmtAttr(stmtHandle: CPointer<Unit>, attribute: Int32, value: Int64, stringLength: Int32): Int16
    func sqlDescribeParam(stmtHandle: CPointer<Unit>, parameterNumber: UInt16, dataTypePtr: CPointer<Int16>,
        parameterSizePtr: CPointer<UInt64>, decimalDigitsPtr: CPointer<Int16>, nullablePtr: CPointer<Int16>): Int16
    func sqlNumParams(stmtHandle: CPointer<Unit>, parameterCountPtr: CPointer<Int16>): Int16
    func sqlBindParameter(stmtHandle: CPointer<Unit>, parameterNumber: UInt16, inputOutputType: Int16,
        valueType: Int16, parameterType: Int16, columnSize: UInt64, decimalDigits: Int16,
        parameterValuePtr: CPointer<Unit>, bufferLength: Int64, strLenOrIndPtr: CPointer<Int64>): Int16
    func sqlNumResultCols(stmtHandle: CPointer<Unit>, columnCountPtr: CPointer<Int16>): Int16
    func sqlDescribeCol(stmtHandle: CPointer<Unit>, columnNumber: UInt16, columnName: CString, bufferLength: Int16,
        nameLengthPtr: CPointer<Int16>, dataTypePtr: CPointer<Int16>, columnSizePtr: CPointer<Int64>,
        decimalDigitsPtr: CPointer<Int16>, nullablePtr: CPointer<Int16>): Int16
    func sqlRowCount(stmtHandle: CPointer<Unit>, rowCountPtr: CPointer<Int64>): Int16
    func sqlFetch(stmtHandle: CPointer<Unit>): Int16
    func sqlBindCol(stmtHandle: CPointer<Unit>, columnNumber: UInt16, targetType: Int16,
        targetValuePtr: CPointer<Unit>, bufferLength: Int64, strLenOrIndPtr: CPointer<Int64>): Int16
    func sqlGetData(stmtHandle: CPointer<Unit>, colOrParamNum: UInt16, targetType: Int16,
        targetValuePtr: CPointer<Unit>, bufferLength: Int64, strLenOrIndPtr: CPointer<Int64>): Int16
    func sqlCloseCursor(stmtHandle: CPointer<Unit>): Unit
    func sqlGetInfo(dbcHandle: CPointer<Unit>, infoType: UInt16, infoValuePtr: CPointer<Unit>, bufferLength: Int16,
        stringLengthPtr: CPointer<Int16>): Int16

    func malloc(size: UIntNative): CPointer<Unit>
    func realloc(ptr: CPointer<Unit>, size: Int64): CPointer<Unit>
    func free(ptr: CPointer<Unit>): Unit

    func diagnoseException(handleType: Int16, handle: CPointer<Unit>): SqlException
}
