package odbc

// 时间戳，无 TIME ZONE
public class SqlTimestampWithoutTz <: SqlDbType {
    private var v: DateTime

    public init(v: DateTime) {
        this.v = v
    }

    public mut prop value: DateTime {
        get() {
            v
        }

        set(value) {
            v = value
        }
    }

    /*
     * 类型名称
     */
    public prop name: String {
        get() {
            "SqlTimestampWithoutTz"
        }
    }
}

// 时间戳，无 TIME ZONE
public class SqlNullableTimestampWithoutTz <: SqlNullableDbType {
    private var v: ?DateTime

    public init(v: ?DateTime) {
        this.v = v
    }

    public mut prop value: ?DateTime {
        get() {
            v
        }

        set(value) {
            v = value
        }
    }

    /*
     * 类型名称
     */
    public prop name: String {
        get() {
            "SqlNullableTimestampWithoutTz"
        }
    }
}
