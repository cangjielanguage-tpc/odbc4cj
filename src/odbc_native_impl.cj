package odbc4cj

public class RealOdbcNativeApi <: OdbcNativeApi {
    public func sqlAllocHandle(handleType: Int16, inputHandle: CPointer<Unit>, outputHandle: CPointer<CPointer<Unit>>): Int16 {
        unsafe { SQLAllocHandle(handleType, inputHandle, outputHandle) }
    }

    public func sqlFreeHandle(handleType: Int16, handle: CPointer<Unit>): Unit {
        unsafe { SQLFreeHandle(handleType, handle) }
    }

    public func sqlSetEnvAttr(envHandle: CPointer<Unit>, attribute: Int32, value: Int64, stringLength: Int32): Int16 {
        unsafe { SQLSetEnvAttr(envHandle, attribute, value, stringLength) }
    }

    public func sqlDriverConnect(connectionHandle: CPointer<Unit>, windowHandle: CPointer<Unit>, inConnectionString: CString,
                                  stringLength1: Int16, outConnectionString: CPointer<UInt8>, bufferLength: Int16, stringLength2Ptr: CPointer<Int16>,
                                  driverCompletion: UInt16): Int16 {
        unsafe { SQLDriverConnect(connectionHandle, windowHandle, inConnectionString,
            stringLength1, outConnectionString, bufferLength, stringLength2Ptr, driverCompletion) }
    }
    public func sqlDisconnect(connectionHandle: CPointer<Unit>): Unit {
        unsafe { SQLDisconnect(connectionHandle) }
    }

    public func sqlGetDiagRec(handleType: Int16, handle: CPointer<Unit>, recNumber: Int16, sqlState: CPointer<Int8>,
                               nativeError: CPointer<Int32>, messageText: CPointer<Int8>, bufferLength: Int16,
                               textLength: CPointer<Int16>): Int16 {
        unsafe { SQLGetDiagRec(handleType, handle, recNumber, sqlState, nativeError, messageText, bufferLength, textLength) }
    }

    public func sqlSetConnectAttr(dbcHandle: CPointer<Unit>, attribute: Int32, value: Int64, stringLength: Int32): Int16 {
        unsafe { SQLSetConnectAttr(dbcHandle, attribute, value, stringLength) }
    }

    public func sqlEndTran(handleType: Int16, handle: CPointer<Unit>, completionType: Int16): Int16 {
        unsafe { SQLEndTran(handleType, handle, completionType) }
    }

    public func sqlExecDirect(stmtHandle: CPointer<Unit>, statementText: CString, textLength: Int32): Int16 {
        unsafe { SQLExecDirect(stmtHandle, statementText, textLength) }
    }

    public func sqlExecute(stmtHandle: CPointer<Unit>): Int16 {
        unsafe { SQLExecute(stmtHandle) }
    }

    public func sqlPrepare(stmtHandle: CPointer<Unit>, statementText: CString, textLength: Int32): Int16 {
        unsafe { SQLPrepare(stmtHandle, statementText, textLength) }
    }

    public func sqlSetStmtAttr(stmtHandle: CPointer<Unit>, attribute: Int32, value: Int64, stringLength: Int32): Int16 {
        unsafe { SQLSetStmtAttr(stmtHandle, attribute, value, stringLength) }
    }

    public func sqlDescribeParam(stmtHandle: CPointer<Unit>, parameterNumber: UInt16, dataTypePtr: CPointer<Int16>,
                                  parameterSizePtr: CPointer<UInt64>, decimalDigitsPtr: CPointer<Int16>, nullablePtr: CPointer<Int16>): Int16 {
        unsafe { SQLDescribeParam(stmtHandle, parameterNumber, dataTypePtr, parameterSizePtr, decimalDigitsPtr, nullablePtr) }
    }

    public func sqlNumParams(stmtHandle: CPointer<Unit>, parameterCountPtr: CPointer<Int16>): Int16 {
        unsafe { SQLNumParams(stmtHandle, parameterCountPtr) }
    }

    public func sqlBindParameter(stmtHandle: CPointer<Unit>, parameterNumber: UInt16, inputOutputType: Int16,
                                  valueType: Int16, parameterType: Int16, columnSize: UInt64, decimalDigits: Int16,
                                  parameterValuePtr: CPointer<Unit>, bufferLength: Int64, strLenOrIndPtr: CPointer<Int64>): Int16 {
        unsafe { SQLBindParameter(stmtHandle, parameterNumber, inputOutputType, valueType, parameterType,
            columnSize, decimalDigits, parameterValuePtr, bufferLength, strLenOrIndPtr) }
    }

    public func sqlNumResultCols(stmtHandle: CPointer<Unit>, columnCountPtr: CPointer<Int16>): Int16 {
        unsafe { SQLNumResultCols(stmtHandle, columnCountPtr) }
    }

    public func sqlDescribeCol(stmtHandle: CPointer<Unit>, columnNumber: UInt16, columnName: CString, bufferLength: Int16,
                                nameLengthPtr: CPointer<Int16>, dataTypePtr: CPointer<Int16>, columnSizePtr: CPointer<Int64>,
                                decimalDigitsPtr: CPointer<Int16>, nullablePtr: CPointer<Int16>): Int16 {
        unsafe { SQLDescribeCol(stmtHandle, columnNumber, columnName, bufferLength,
            nameLengthPtr, dataTypePtr, columnSizePtr, decimalDigitsPtr, nullablePtr) }
    }

    public func sqlRowCount(stmtHandle: CPointer<Unit>, rowCountPtr: CPointer<Int64>): Int16 {
        unsafe { SQLRowCount(stmtHandle, rowCountPtr) }
    }

    public func sqlFetch(stmtHandle: CPointer<Unit>): Int16 {
        unsafe { SQLFetch(stmtHandle) }
    }

    public func sqlBindCol(stmtHandle: CPointer<Unit>, columnNumber: UInt16, targetType: Int16,
                            targetValuePtr: CPointer<Unit>, bufferLength: Int64, strLenOrIndPtr: CPointer<Int64>): Int16 {
        unsafe { SQLBindCol(stmtHandle, columnNumber, targetType, targetValuePtr, bufferLength, strLenOrIndPtr) }
    }

    public func sqlGetData(stmtHandle: CPointer<Unit>, colOrParamNum: UInt16, targetType: Int16,
                            targetValuePtr: CPointer<Unit>, bufferLength: Int64, strLenOrIndPtr: CPointer<Int64>): Int16 {
        unsafe { SQLGetData(stmtHandle, colOrParamNum, targetType, targetValuePtr, bufferLength, strLenOrIndPtr) }
    }

    public func sqlCloseCursor(stmtHandle: CPointer<Unit>): Unit {
        unsafe { SQLCloseCursor(stmtHandle) }
    }

    public func sqlGetInfo(dbcHandle: CPointer<Unit>, infoType: UInt16, infoValuePtr: CPointer<Unit>, bufferLength: Int16,
                            stringLengthPtr: CPointer<Int16>): Int16 {
        unsafe { SQLGetInfo(dbcHandle, infoType, infoValuePtr, bufferLength, stringLengthPtr) }
    }

    public func malloc(size: UIntNative): CPointer<Unit> {
        var p = unsafe{LibC.malloc<UInt8>(count:Int64(size))}
        CPointer<Unit>(p)
    }

    public func realloc(ptr: CPointer<Unit>, size: Int64): CPointer<Unit> {
        var p = unsafe{LibC.malloc<UInt8>(count:size)}
        CPointer<Unit>(p)
    }

    public func free(ptr: CPointer<Unit>): Unit {
        if(!ptr.isNull()) {
            unsafe { LibC.free<UInt8>(CPointer<UInt8>(ptr)) }
        }
    }

    public func diagnoseException(handleType: Int16, handle: CPointer<Unit>): SqlException { 
        diagnoseException(handleType, handle)
    }
}
