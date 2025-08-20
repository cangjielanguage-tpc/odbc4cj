/*
 * @Copyright (c) Huawei Technologies Co., Ltd. 2025-2025. All rights reserved.
 */
package odbc4cj

public class OdbcTypeTime{
    private var dateTime: DateTime
    /*
     * 
     *
     * 参数 inputStream - 
     */
    public init(dateTime: DateTime) {
        this.dateTime = dateTime
    }

    /*
     * 数据
     */
    public mut prop value: DateTime {
        get() {
            dateTime
        }
        set(value) {
            dateTime = value
        }
    }

    /*
     * 类型名称
     */
    public prop name: String {
        get() {
            "TIME"
        }
    }
}