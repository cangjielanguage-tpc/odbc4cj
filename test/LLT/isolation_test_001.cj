// EXEC: cjc %import-path %L %l %f
// EXEC: ./main

import std.database.sql.*
import std.io.*
import std.time.*
import std.regex.*
import std.math.*
import odbc4cj.*
import std.unittest.*
import std.unittest.testmacro.*

main(): Int64 {
    let filterResultTest: OdbcTest = OdbcTest()

    filterResultTest.test001()

    return 0
}

@Test
public class OdbcTest {
    // 回归覆盖：事务隔离级别读取
    // 修复前 getter 误用 SQLGetInfo(SQL_TXN_ISOLATION_OPTION)（驱动支持集合位掩码），
    // 读写不一致；修复后读写同用 SQLGetConnectAttr(SQL_ATTR_TXN_ISOLATION)
    @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var tran = conn.createTransaction()
        // MySQL InnoDB 默认 REPEATABLE_READ，设置后读回必须一致
        tran.isoLevel = ReadCommitted
        @Assert(ReadCommitted, tran.isoLevel)
        tran.isoLevel = Serializable
        @Assert(Serializable, tran.isoLevel)
        tran.isoLevel = RepeatableRead
        @Assert(RepeatableRead, tran.isoLevel)
        conn.close()
    }
}
