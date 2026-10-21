package odbc4cj

// 自动注册驱动
let _ = DriverManager.register("odbc", OdbcDriver())

public class OdbcDriver <: Driver {
    private let nativeApi: OdbcNativeApi

    /*
     * 初始化驱动
     *
     * 异常 SqlException - 内存不足导致初始化失败
     */
    public init() {
        this.nativeApi = RealOdbcNativeApi()
    }

    /*
     * 初始化驱动(测试代码注入Mock使用)
     *
     * 异常 SqlException - 内存不足导致初始化失败
     */
    public init(nativeApi: OdbcNativeApi) {
        this.nativeApi = nativeApi
    }

    /**
     * 驱动名称 (不支持)
     */
    public override prop name: String {
        get() {
            ""
        }
    }

    /**
     * 驱动版本 (不支持)
     */
    public override prop version: String {
        get() {
            ""
        }
    }

    /**
     * 指示驱动程序是否与连接池亲和。(不支持)
     * 如果否，则不建议使用连接池。
     * 比如 sqlite 驱动连接池化的收益不明显不建议使用连接池
     */
    public override prop preferredPooling: Bool {
        get() {
            false
        }
    }

    /**
     * 通过 connectionString 和选项打开数据源
     * 参数 connectionString - 数据库连接字符串, 格式为 "DATABASE=sql;UID=abc;PWD=123"
     * 参数 opts - key, value 的 tuple 数组，打开数据源的选项
     *            opts 只有 ("SQL_ATTR_AUTOCOMMIT", "SQL_AUTOCOMMIT_OFF") 和 ("SQL_ATTR_AUTOCOMMIT", "SQL_AUTOCOMMIT_ON")
     *            2个选项，用来设置 sql 语句提交方式
     * 返回值 Datasource - 数据源实例
     */
    public override func open(connectionString: String, opts: Array<(String, String)>): Datasource {
        let datasource = OdbcDatasource(nativeApi)
        //解析并验证连接字符串
        if (connectionString.size > 0) {
            let fullConnStr = parseAndValidateConnectionString(connectionString)
            datasource.setOption(SqlOption.URL, fullConnStr)
        }
        //opts 追加/覆盖选项
        for ((k, v) in opts) {
            datasource.setOption(k, v)
        }

        return PooledDatasource(datasource)
    }

    /**
     * 解析并验证ODBC连接字符串
     * 参数ConnectionString - ODBC连接字符串格式
     * 返回值 String -完整连接字符串
     * 异常SqlException - 连接字符串格式错误、含非标准键或缺少必需键
     */
    private func parseAndValidateConnectionString(connectionString: String): String {
        var connParts = HashMap<String, String>()
        let arr = connectionString.split(";")
        if (arr.size < 3) {
            throw OdbcSqlException("", "Url is error", 0)
        }
        for (i in 0..arr.size) {
            var list = arr[i].split("=")
            if (list.size != 2) {
                throw OdbcSqlException("", "Url is error", 0)
            }
            let upperKey = list[0].toAsciiUpper()
            if (upperKey == "DRIVER" || upperKey == "DSN" || upperKey == "SERVER" || upperKey == "SERVERNAME" ||
                upperKey == "PORT" || upperKey == "DATABASE" || upperKey == "UID" || upperKey == "PWD") {
                //标准ODBC键：转大写存储（ODBC标准键大小写不敏感）
                connParts[upperKey] = list[1]
            } else {
                //非标准键：对齐 1.1.3 契约，直接报 Url is error
                throw OdbcSqlException("", "Url is error", 0)
            }
        }
        //DATABASE/UID/PWD必须存在
        if (!connParts.contains("DATABASE")) {
            throw OdbcSqlException("", "Url is error", 0)
        }
        if (!connParts.contains("UID")) {
            throw OdbcSqlException("", "Url is error", 0)
        }
        if (!connParts.contains("PWD")) {
            throw OdbcSqlException("", "Url is error", 0)
        }
        //构建完整连接字符串传递给OdbcDatasource(用于SQLDriverConnect)
        var fullConnStr = ""
        for ((k, v) in connParts) {
            if (!fullConnStr.isEmpty()) {
                fullConnStr = fullConnStr + ";"
            }
            fullConnStr = fullConnStr + "${k}=${v}"
        }
        return fullConnStr
    }
}
