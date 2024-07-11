/*
 * @Copyright (c) Huawei Technologies Co., Ltd. 2023-2024. All rights reserved.
 */
 
package odbc

public class OdbcColumnInfo <: ColumnInfo {
    private var lName: String
    private var lTypeName: String
    private var lDisplaySize: Int64
    private var lLength: Int64
    private var lScale: Int64
    private var lNullable: Bool

    public init() {
        lName = ""
        lTypeName = ""
        lDisplaySize = 0
        lLength = 0
        lScale = 0
        lNullable = false
    }

    public init(name: String, typeName: String, displaySize: Int64, length: Int16, scale: Int64, nullable: Int16) {
        lName = name
        lTypeName = typeName
        lDisplaySize = displaySize
        lLength = Int64(length)
        lScale = scale
        if (nullable == SQL_NO_NULLS) {
            lNullable = false
        } else {
            lNullable = true
        }
    }

    // 列名或者别名
    public override prop name: String {
        get() {
            lName
        }
    }

    // 列类型名称，如果在 SqlDataType 中定义，返回 SqlDataType.toString(), 如果未在 SqlDataType 中定义，由数据库驱动定义
    public override prop typeName: String {
        get() {
            lTypeName
        }
    }

    // 列值的最大显示长度，如果无限制，则应该返回 Int64.Max（仍然受数据库的限制）
    public override prop displaySize: Int64 {
        get() {
            lDisplaySize
        }
    }

    /**
     * 获取列值大小。
     * 对于数值数据，这是最大精度。
     * 对于字符数据，这是以字符为单位的长度 。
     * 对于日期时间数据类型，这是字符串表示形式的最大字符长度。
     * 对于二进制数据，这是以字节为单位的长度 。
     * 对于 RowID 数据类型，这是以字节为单位的长度 。
     * 对于列大小不适用的数据类型，返回 0。
     */
    public override prop length: Int64 {
        get() {
            lLength
        }
    }

    // 列值的小数长度，如果无小数部分，返回 0
    public override prop scale: Int64 {
        get() {
            lScale
        }
    }

    // 列值是否允许数据库 Null 值
    public override prop nullable: Bool {
        get() {
            lNullable
        }
    }
}