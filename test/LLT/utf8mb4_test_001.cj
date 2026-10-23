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
    // 回归覆盖：utf8mb4 宽字符支持（SQL_WCHAR/-8、SQL_WVARCHAR/-9）
    // 修复前驱动返回宽字符类型码时 SDK 抛出不支持类型错误（对应 issue #20）
    @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var prepareStatement = conn.prepareStatement("drop table if exists test_llt")
        var rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test_llt(data varchar(20) NOT NULL, datanull varchar(20)) default charset=utf8mb4")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test_llt values(?,?)")
        rowCount = prepareStatement.update([SqlVarchar("汉字😀混合"), SqlNullableVarchar(None)])
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test_llt")
        var queryResult = prepareStatement.query()
        @Assert(true, queryResult.next())
        // utf8mb4 列经 MySQL ODBC 驱动返回 SQL_WVARCHAR(-9)，需路由到字符串读取通道
        @Assert("汉字😀混合", queryResult.get<String>(0))
        @Assert(None, queryResult.getOrNull<String>(1))
        queryResult.close()
        conn.close()
    }
}
