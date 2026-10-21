package odbc4cj

/* Global variables */
/* SQL results */
let SQL_ERROR: Int16 = -1
let SQL_INVALID_HANDLE: Int16 = -2
let SQL_SUCCESS: Int16 = 0
let SQL_SUCCESS_WITH_INFO: Int16 = 1

/* Environment attribute */
let SQL_ATTR_ODBC_VERSION: Int32 = 200

/* Value for ODBC version */
let SQL_OV_ODBC3: Int64 = 3

/* Handle types */
let SQL_HANDLE_ENV: Int16 = 1
let SQL_HANDLE_DBC: Int16 = 2
let SQL_HANDLE_STMT: Int16 = 3
let SQL_HANDLE_DESC: Int16 = 4

/* Connection attribute */
public let SQL_ATTR_ACCESS_MODE: Int32 = 101
public let SQL_ATTR_ASYNC_DBC_EVENT: Int32 = 119
public let SQL_ATTR_ASYNC_DBC_FUNCTIONS_ENABLE: Int32 = 117
public let SQL_ATTR_ASYNC_ENABLE: Int32 = 4
public let SQL_ATTR_AUTO_IPD: Int32 = 10001
public let SQL_ATTR_AUTOCOMMIT: Int32 = 102
public let SQL_ATTR_CONNECTION_DEAD: Int32 = 1209
public let SQL_ATTR_CONNECTION_TIMEOUT: Int32 = 113
public let SQL_ATTR_CURRENT_CATALOG: Int32 = 109
public let SQL_ATTR_DBC_INFO_TOKEN: Int32 = 118
public let SQL_ATTR_ENLIST_IN_DTC: Int32 = 1207
public let SQL_ATTR_LOGIN_TIMEOUT: Int32 = 103
public let SQL_ATTR_METADATA_ID: Int32 = 10014
public let SQL_ATTR_ODBC_CURSORS: Int32 = 110
public let SQL_ATTR_PACKET_SIZE: Int32 = 112
public let SQL_ATTR_QUIET_MODE: Int32 = 111
public let SQL_ATTR_TRACE: Int32 = 104
public let SQL_ATTR_TRACEFILE: Int32 = 105
public let SQL_ATTR_TRANSLATE_LIB: Int32 = 106
public let SQL_ATTR_TRANSLATE_OPTION: Int32 = 107
public let SQL_ATTR_TXN_ISOLATION: Int32 = 108
public let SQL_ATTR_QUERY_TIMEOUT: Int32 = 6

/* Autocommit options */
public let SQL_AUTOCOMMIT_OFF: Int64 = 0
public let SQL_AUTOCOMMIT_ON: Int64 = 1

/* End transaction options */
let SQL_COMMIT: Int16 = 0
let SQL_ROLLBACK: Int16 = 1

/* Attribute type options */
let SQL_IS_POINTER: Int32 = -4
let SQL_IS_UINTEGER: Int32 = -5
let SQL_IS_INTEGER: Int32 = -6
let SQL_IS_USMALLINT: Int32 = -7
let SQL_IS_SMALLINT: Int32 = -8
let SQL_NO_TOTAL: Int64 = -4

/* Misc */
let SQL_NTS: Int16 = -3

/* Bind parameter options */
let SQL_PARAM_INPUT: Int16 = 1
let SQL_NO_DATA: Int16 = 100
let SQL_NULL_DATA: Int64 = -1
let SQL_UNKNOWN_TYPE: Int16 = 0
let SQL_CHAR: Int16 = 1
let SQL_NUMERIC: Int16 = 2
let SQL_DECIMAL: Int16 = 3
let SQL_INTEGER: Int16 = 4
let SQL_SMALLINT: Int16 = 5
let SQL_FLOAT: Int16 = 6
let SQL_REAL: Int16 = 7
let SQL_DOUBLE: Int16 = 8
let SQL_VARCHAR: Int16 = 12
let SQL_TYPE_DATE: Int16 = 91
let SQL_TYPE_TIME: Int16 = 92
let SQL_TYPE_TIMESTAMP: Int16 = 93
let SQL_INTERVAL_YEAR: Int16 = 101
let SQL_INTERVAL_MONTH: Int16 = 102
let SQL_INTERVAL_DAY: Int16 = 103
let SQL_INTERVAL_HOUR: Int16 = 104
let SQL_INTERVAL_MINUTE: Int16 = 105
let SQL_INTERVAL_SECOND: Int16 = 106
let SQL_INTERVAL_YEAR_TO_MONTH: Int16 = 107
let SQL_INTERVAL_DAY_TO_HOUR: Int16 = 108
let SQL_INTERVAL_DAY_TO_MINUTE: Int16 = 109
let SQL_INTERVAL_DAY_TO_SECOND: Int16 = 110
let SQL_INTERVAL_HOUR_TO_MINUTE: Int16 = 111
let SQL_INTERVAL_HOUR_TO_SECOND: Int16 = 112
let SQL_INTERVAL_MINUTE_TO_SECOND: Int16 = 113
let SQL_LONGVARCHAR: Int16 = -1
let SQL_BINARY: Int16 = -2
let SQL_WCHAR: Int16 = -8
let SQL_WVARCHAR: Int16 = -9
let SQL_WLONGVARCHAR: Int16 = -10
let SQL_VARBINARY: Int16 = -3
let SQL_LONGVARBINARY: Int16 = -4
let SQL_BIGINT: Int16 = -5
let SQL_TINYINT: Int16 = -6
let SQL_BIT: Int16 = -7
let SQL_SIGNED_OFFSET: Int16 = -20
let SQL_UNSIGNED_OFFSET: Int16 = -22
let SQL_C_UNKNOWN_TYPE: Int16 = SQL_UNKNOWN_TYPE
let SQL_C_CHAR: Int16 = SQL_CHAR
let SQL_C_LONG: Int16 = SQL_INTEGER
let SQL_C_SHORT: Int16 = SQL_SMALLINT
let SQL_C_FLOAT: Int16 = SQL_REAL
let SQL_C_DOUBLE: Int16 = SQL_DOUBLE
let SQL_C_BINARY: Int16 = SQL_BINARY
let SQL_C_BIT: Int16 = SQL_BIT
let SQL_C_SBIGINT: Int16 = SQL_BIGINT + SQL_SIGNED_OFFSET
let SQL_C_UBIGINT: Int16 = SQL_BIGINT + SQL_UNSIGNED_OFFSET
let SQL_C_TINYINT: Int16 = SQL_TINYINT
let SQL_C_SLONG: Int16 = SQL_C_LONG + SQL_SIGNED_OFFSET
let SQL_C_SSHORT: Int16 = SQL_C_SHORT + SQL_SIGNED_OFFSET
let SQL_C_STINYINT: Int16 = SQL_TINYINT + SQL_SIGNED_OFFSET
let SQL_C_ULONG: Int16 = SQL_C_LONG + SQL_UNSIGNED_OFFSET
let SQL_C_USHORT: Int16 = SQL_C_SHORT + SQL_UNSIGNED_OFFSET
let SQL_C_UTINYINT: Int16 = SQL_TINYINT + SQL_UNSIGNED_OFFSET
let SQL_C_TYPE_DATE: Int16 = SQL_TYPE_DATE
let SQL_C_TYPE_TIME: Int16 = SQL_TYPE_TIME
let SQL_C_TYPE_TIMESTAMP: Int16 = SQL_TYPE_TIMESTAMP
let SQL_C_INTERVAL_YEAR: Int16 = 101
let SQL_C_INTERVAL_MONTH: Int16 = 102
let SQL_C_INTERVAL_DAY: Int16 = 103
let SQL_C_INTERVAL_HOUR: Int16 = 104
let SQL_C_INTERVAL_MINUTE: Int16 = 105
let SQL_C_INTERVAL_SECOND: Int16 = 106
let SQL_C_INTERVAL_YEAR_TO_MONTH: Int16 = 107
let SQL_C_INTERVAL_DAY_TO_HOUR: Int16 = 108
let SQL_C_INTERVAL_DAY_TO_MINUTE: Int16 = 109
let SQL_C_INTERVAL_DAY_TO_SECOND: Int16 = 110
let SQL_C_INTERVAL_HOUR_TO_MINUTE: Int16 = 111
let SQL_C_INTERVAL_HOUR_TO_SECOND: Int16 = 112
let SQL_C_INTERVAL_MINUTE_TO_SECOND: Int16 = 113

/* Lengths */
let LEN_POINTER: UIntNative = 8
let LEN_Int32: UIntNative = 4
let LEN_Int16: UIntNative = 2
let LEN_SQLSTATE = 6
let LEN_MESSAGE = 512
let STRING_LEN: UInt64 = 8000
let SQL_NO_NULLS: Int16 = 0
let SQL_NULLABLE: Int16 = 1
let SQL_NULLABLE_UNKNOWN: Int16 = 2
let SQL_IS_YEAR: Int32 = 1
let SQL_IS_MONTH: Int32 = 2
let SQL_IS_DAY: Int32 = 3
let SQL_IS_HOUR: Int32 = 4
let SQL_IS_MINUTE: Int32 = 5
let SQL_IS_SECOND: Int32 = 6
let SQL_IS_YEAR_TO_MONTH: Int32 = 7
let SQL_IS_DAY_TO_HOUR: Int32 = 8
let SQL_IS_DAY_TO_MINUTE: Int32 = 9
let SQL_IS_DAY_TO_SECOND: Int32 = 10
let SQL_IS_HOUR_TO_MINUTE: Int32 = 11
let SQL_IS_HOUR_TO_SECOND: Int32 = 12
let SQL_IS_MINUTE_TO_SECOND: Int32 = 13
let SQL_DRIVER_NAME: UInt16 = 6
let SQL_DRIVER_VER: UInt16 = 7
let SQL_TXN_ISOLATION_OPTION: UInt16 = 72

/* SQL_TXN_ISOLATION_OPTION bitmasks */
let SQL_TXN_READ_UNCOMMITTED: UInt32 = 1
let SQL_TXN_READ_COMMITTED: UInt32 = 2
let SQL_TXN_REPEATABLE_READ: UInt32 = 4
let SQL_TXN_SERIALIZABLE: UInt32 = 8
let LEN_MALLOC_1: UIntNative = 1
let LEN_MALLOC_2: UIntNative = 2
let LEN_MALLOC_4: UIntNative = 4
let LEN_MALLOC_6: UIntNative = 6
let LEN_MALLOC_8: UIntNative = 8
let LEN_MALLOC_16: UIntNative = 16

/**SQLDRIVERCONNENT DriverCompletion*/
let SQL_DRIVER_NOPROMPT: UInt16 = 0
let SQL_MODE_READ_WRITE: Int64 = 0
let SQL_MODE_READ_ONLY: Int64 = 1
let SQL_SERVER_NAME: UInt16 = 13
let SQL_DBMS_NAME: UInt16 = 17
let SQL_DBMS_VER: UInt16 = 18
let SQL_DATA_SOURCE_NAME: UInt16 = 2

@C
struct DATE_STRUCT {
    var year: Int16 = 0
    var month: Int16 = 0
    var day: Int16 = 0
}

@C
struct TIME_STRUCT {
    var hour: Int16 = 0
    var minute: Int16 = 0
    var second: Int16 = 0
}

@C
struct TIMESTAMP_STRUCT {
    var year: Int16 = 0
    var month: Int16 = 0
    var day: Int16 = 0
    var hour: Int16 = 0
    var minute: Int16 = 0
    var second: Int16 = 0
    var fraction: UInt32 = 0
}

struct DataBuffer {
    var data: CPointer<Unit> = CPointer<Unit>()
    var len: Int64 = 0
}

public class OdbcSqlException <: SqlException {
    private let odbcSqlState: String
    private let odbcNativeErrorCode: Int64

    init(sqlState: String, message: String, nativeError: Int64) {
        // std SqlException.message 会拼接 SqlState/errorCode；给 super 传空 sqlState，
        // 使 message 格式为 "<原始消息>, errorCode: N"，真实 sqlState 通过 odbcState 暴露
        super(message, "", nativeError)
        this.odbcSqlState = sqlState
        this.odbcNativeErrorCode = nativeError
    }

    public prop odbcState: String {
        get() {
            return odbcSqlState
        }
    }

    public prop odbcNativeCode: Int64 {
        get() {
            return odbcNativeErrorCode
        }
    }
}

func diagnoseSqlException(HandleType: Int16, Handle: CPointer<Unit>): SqlException {
    var sqlstatePtr = LibC.malloc<Int8>(count: LEN_SQLSTATE)
    if (sqlstatePtr.isNull()) {
        throw SqlException("Native malloc failed.")
    }
    var nativeErrorPtr = LibC.malloc<Int32>()
    if (nativeErrorPtr.isNull()) {
        unsafe { LibC.free(sqlstatePtr) }
        throw SqlException("Native malloc failed.")
    }
    var messageText = LibC.malloc<Int8>(count: LEN_MESSAGE)
    if (messageText.isNull()) {
        unsafe {
            LibC.free(sqlstatePtr)
            LibC.free(nativeErrorPtr)
        }
        throw SqlException("Native malloc failed.")
    }

    var totalBytesPtr = LibC.malloc<Int16>()
    if (totalBytesPtr.isNull()) {
        unsafe {
            LibC.free(sqlstatePtr)
            LibC.free(nativeErrorPtr)
            LibC.free(messageText)
        }
        throw SqlException("Native malloc failed.")
    }
    var msgLen = Int16(LEN_MESSAGE)
    var i: Int16 = 1
    var ret: Int16
    var sqlException: OdbcSqlException = OdbcSqlException("", "", 0)

    do {
        ret = unsafe { SQLGetDiagRec(HandleType, Handle, i, sqlstatePtr, nativeErrorPtr, messageText, msgLen,
            totalBytesPtr) }
        if (ret == SQL_NO_DATA) {
            break
        }

        var totalBytes = unsafe { CPointer<Int16>(totalBytesPtr).read() }
        if (SQLSucceeded(ret) && totalBytes > msgLen - 1) {
            msgLen = totalBytes + 1
            var msgPtr = unsafe { realloc(CPointer<Unit>(messageText), Int64(msgLen)) }
            if (msgPtr.isNull()) {
                unsafe {
                    LibC.free(sqlstatePtr)
                    LibC.free(nativeErrorPtr)
                    LibC.free(messageText)
                    LibC.free(totalBytesPtr)
                }
                throw SqlException("Native realloc failed.")
            }
            messageText = CPointer<Int8>(msgPtr)

            ret = unsafe { SQLGetDiagRec(HandleType, Handle, i, sqlstatePtr, nativeErrorPtr, messageText, msgLen,
                totalBytesPtr) }
            if (!SQLSucceeded(ret)) {
                break
            }
        }

        // Not always NULL terminated (MS Access)
        unsafe { sqlstatePtr.write(5, 0) }

        var text = CString(CPointer<UInt8>(messageText))
        var nativeError = unsafe { CPointer<Int32>(nativeErrorPtr).read() }
        var sqlstate = CString(CPointer<UInt8>(sqlstatePtr))
        sqlException = OdbcSqlException(sqlstate.toString(), text.toString(), Int64(nativeError))
        i++
        //安全限制：最多读取10条诊断记录，防止异常情况下无限循环
        if (i > 10) {
            break
        }
    } while (ret != SQL_NO_DATA && SQLSucceeded(ret))

    unsafe {
        LibC.free(sqlstatePtr)
        LibC.free(nativeErrorPtr)
        LibC.free(messageText)
        LibC.free(totalBytesPtr)
    }

    return sqlException
}

func SQLSucceeded(res: Int16): Bool {
    return (res == SQL_SUCCESS_WITH_INFO) || (res == SQL_SUCCESS)
}

func sqlTypeToString(`type`: Int16): String {
    let t = `type`
    return match (t) {
        case 0 => "SQL_UNKNOWN_TYPE"
        case 1 => "SQL_CHAR"
        case 2 => "SQL_NUMERIC"
        case 3 => "SQL_DECIMAL"
        case 4 => "SQL_INTEGER"
        case 5 => "SQL_SMALLINT"
        case 6 => "SQL_FLOAT"
        case 7 => "SQL_REAL"
        case 8 => "SQL_DOUBLE"
        case 12 => "SQL_VARCHAR"
        case -8 => "SQL_WCHAR"
        case -9 => "SQL_WVARCHAR"
        case -10 => "SQL_WLONGVARCHAR"
        case 91 => "SQL_TYPE_DATE"
        case 92 => "SQL_TYPE_TIME"
        case 93 => "SQL_TYPE_TIMESTAMP"
        case 101 => "SQL_INTERVAL_YEAR"
        case 102 => "SQL_INTERVAL_MONTH"
        case 103 => "SQL_INTERVAL_DAY"
        case 104 => "SQL_INTERVAL_HOUR"
        case 105 => "SQL_INTERVAL_MINUTE"
        case 106 => "SQL_INTERVAL_SECOND"
        case 107 => "SQL_INTERVAL_YEAR_TO_MONTH"
        case 108 => "SQL_INTERVAL_DAY_TO_HOUR"
        case 109 => "SQL_INTERVAL_DAY_TO_MINUTE"
        case 110 => "SQL_INTERVAL_DAY_TO_SECOND"
        case 111 => "SQL_INTERVAL_HOUR_TO_MINUTE"
        case 112 => "SQL_INTERVAL_HOUR_TO_SECOND"
        case 113 => "SQL_INTERVAL_MINUTE_TO_SECOND"
        case -1 => "SQL_LONGVARCHAR"
        case -2 => "SQL_BINARY"
        case -3 => "SQL_VARBINARY"
        case -4 => "SQL_LONGVARBINARY"
        case -5 => "SQL_BIGINT"
        case -6 => "SQL_TINYINT"
        case -7 => "SQL_BIT"
        case -27 => "SQL_C_SSHORT"
        case -16 => "SQL_C_SLONG"
        case -20 => "SQL_C_SBIGINT"
        case -21 => "SQL_C_SLONG"
        case -22 => "SQL_C_UBIGINT"
        case -23 => "SQL_C_USHORT"
        case -24 => "SQL_C_SSHORT"
        case -25 => "SQL_C_ULONG"
        case -26 => "SQL_C_UTINYINT"
        case -27 => "SQL_C_STINYINT"
        case _ => "SQL_UNKNOWN (${t})"
    }
}

struct ParamInfo {
    var valueType: Int16 = 0
    var parameterType: Int16 = 0
    var columnSize: UInt64 = 0
    var decimalDigits: Int16 = 0
    var parameterValuePtr: CPointer<Unit> = CPointer<Unit>()
    var bufferLength: Int64 = 0
    var strLenOrInd: CPointer<Int64> = CPointer<Int64>()
    var isString: Bool = false
    var cstring: CString = CString(CPointer<UInt8>())
    var isArrary: Bool = false
    var cptrHand: CPointerHandle<UInt8> = unsafe { acquireArrayRawData<UInt8>(Array<UInt8>()) }
}
