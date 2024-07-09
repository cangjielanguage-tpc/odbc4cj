package odbc

/* 执行 Insert、Update、Delete 语句产生的结果接口 */
public class OdbcUpdateResult <: UpdateResult {
    private var resultCount: Int64

    public init(rowCount: Int64) {
        this.resultCount = rowCount
    }

    /*
     * 执行 Insert, Update, Delete 语句影响的行数
     */
    public prop rowCount: Int64 {
        get() {
            this.resultCount
        }
    }

    /*
     * 执行 Insert 语句自动生成的最后 row ID，如果不支持则为 0
     */
    public prop lastInsertId: Int64 {
        get() {
            0
        }
    }
}
