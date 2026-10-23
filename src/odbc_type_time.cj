/*
 * @Copyright (c) Huawei Technologies Co., Ltd. 2025-2025. All rights reserved.
 */
package odbc4cj

public class OdbcTypeTime{
    private var dateTime: DateTime
    /*
     * 构造时间值
     *
     * 参数 dateTime - 包含时分秒的时间值
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