package odbc4cj

public class OdbcDatasource <: Datasource {
    private let nativeApi: OdbcNativeApi
    private var options: HashMap<String, String>
    private let closed = AtomicBool(false)


    /*
     * 初始化数据源
     */
    public init(nativeApi: OdbcNativeApi) {
        this.nativeApi = nativeApi
        this.options = HashMap<String, String>()
    }

    /*
     * 初始化数据源（内部创建原生 API，不经驱动池化包装，connect() 返回真实连接）
     */
    public init() {
        this.nativeApi = RealOdbcNativeApi()
        this.options = HashMap<String, String>()
    }

    /*
     * 设置连接选项
     * 参数 key - 选项键（如SqlOption.URL, SqlOption.USERname等）
     * 参数 value - 键对应的值
     */
    public override func setOption(key: String, value: String): Unit {
        checkResource()
        options[key] = value
    }

    /*
     * 设置连接选项（数值型选项，对齐 1.1.3 API）
     */
    public func setOption(key: Int32, value: Int64): Unit {
    }

    /*
     * 返回一个可用的连接
     * 返回值 OdbcConnection - 数据库连接实例
     */
    public override func connect(): OdbcConnection {
        checkResource()
        return OdbcConnection(nativeApi, options)
    }

    /*
     * 关闭数据源
     */
    public override func close(): Unit {
        closed.store(true)
    }

    /*
     * 判断数据源是否已关闭
     * 返回值 Boolean - true表示已关闭，false表示未关闭
     */
    public override func isClosed(): Bool {
        closed.load()
    }

    private func checkResource(): Unit {
        if (isClosed()) {
            throw SqlException("The datasource has been closed.")
        }
    }
}
