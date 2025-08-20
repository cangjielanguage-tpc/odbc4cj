/*
 * @Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights reserved.
 */
 
package odbc4cj

// 时间戳，无 TIME ZONE
@Deprecated
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
@Deprecated
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
