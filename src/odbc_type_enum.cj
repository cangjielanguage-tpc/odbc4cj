package odbc4cj

public enum OdbcTypeEnum <: Equatable<OdbcTypeEnum> & ToString {
    | SqlString
    | SqlArrayByte
    | SqlInputStream
    | SqlClob
    | SqlBool
    | SqlInt8
    | SqlInt16
    | SqlInt32
    | SqlInt64
    | SqlUInt8
    | SqlUInt16
    | SqlUInt32
    | SqlUInt64
    | SqlFloat32
    | SqlFloat64
    | SqlDate
    | SqlTime
    | SqlTimestamp
    | SqlDecimal
    | SqlNull
    | SqlBigInt
    | SqlOther

    /*
     * 枚举是否相等
     *
     * 参数 that - 枚举
     * 返回值 Bool - 是否相等
     */
    public operator func ==(that: OdbcTypeEnum): Bool {
        match ((this, that)) {
            case (SqlString, SqlString) => true
            case (SqlArrayByte, SqlArrayByte) => true
            case (SqlInputStream, SqlInputStream) => true
            case (SqlClob, SqlClob) => true
            case (SqlBool, SqlBool) => true
            case (SqlInt8, SqlInt8) => true
            case (SqlInt16, SqlInt16) => true
            case (SqlInt32, SqlInt32) => true
            case (SqlInt64, SqlInt64) => true
            case (SqlUInt8, SqlUInt8) => true
            case (SqlUInt16, SqlUInt16) => true
            case (SqlUInt32, SqlUInt32) => true
            case (SqlUInt64, SqlUInt64) => true
            case (SqlFloat32, SqlFloat32) => true
            case (SqlFloat64, SqlFloat64) => true
            case (SqlDate, SqlDate) => true
            case (SqlTime, SqlTime) => true
            case (SqlTimestamp, SqlTimestamp) => true
            case (SqlDecimal, SqlDecimal) => true
            case (SqlNull, SqlNull) => true
            case (SqlBigInt, SqlBigInt) => true
            case (SqlOther, SqlOther) => true
            case _ => false
        }
    }

    /*
     * 枚举是否不相等
     *
     * 参数 that - 枚举
     * 返回值 Bool - 是否不相等
     */
    public operator func !=(that: OdbcTypeEnum): Bool {
        return !(this == that)
    }

    public override func toString(): String {
        match (this) {
            case SqlString => return "SqlString"
            case SqlArrayByte => return "SqlArrayByte"
            case SqlInputStream => return "SqlInputStream"
            case SqlClob => return "SqlClob"
            case SqlBool => return "SqlBool"
            case SqlInt8 => return "SqlInt8"
            case SqlInt16 => return "SqlInt16"
            case SqlInt32 => return "SqlInt32"
            case SqlInt64 => return "SqlInt64"
            case SqlUInt8 => return "SqlUInt8"
            case SqlUInt16 => return "SqlUInt16"
            case SqlUInt32 => return "SqlUInt32"
            case SqlUInt64 => return "SqlUInt64"
            case SqlFloat32 => return "SqlFloat32"
            case SqlFloat64 => return "SqlFloat64"
            case SqlDate => return "SqlDate"
            case SqlTime => return "SqlTime"
            case SqlTimestamp => return "SqlTimestamp"
            case SqlDecimal => return "SqlDecimal"
            case SqlNull => return "SqlNull"
            case SqlBigInt => return "SqlBigInt"
            case SqlOther => return "SqlOther"
        }
    }

    public static func fromToString(str: String): OdbcTypeEnum {
        match (str) {
            case "SqlString" => return SqlString
            case "SqlArrayByte" => return SqlArrayByte
            case "SqlInputStream" => return SqlInputStream
            case "SqlClob" => return SqlClob
            case "SqlBool" => return SqlBool
            case "SqlInt8" => return SqlInt8
            case "SqlInt16" => return SqlInt16
            case "SqlInt32" => return SqlInt32
            case "SqlInt64" => return SqlInt64
            case "SqlUInt8" => return SqlUInt8
            case "SqlUInt16" => return SqlUInt16
            case "SqlUInt32" => return SqlUInt32
            case "SqlUInt64" => return SqlUInt64
            case "SqlFloat32" => return SqlFloat32
            case "SqlFloat64" => return SqlFloat64
            case "SqlDate" => return SqlDate
            case "SqlTime" => return SqlTime
            case "SqlTimestamp" => return SqlTimestamp
            case "SqlDecimal" => return SqlDecimal
            case "SqlNull" => return SqlNull
            case "SqlBigInt" => return SqlBigInt
            case "SqlOther" => return SqlOther
            case _ => throw SqlException("Unknown odbc typeEnum:${str}")
        }
    }
}
