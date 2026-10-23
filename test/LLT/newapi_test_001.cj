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
    // 回归覆盖：新版 API 全链路（set<T>/setNull/query()/next()/get<T>/getOrNull）
    // 以及多行遍历与行尾判定
    @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var prepareStatement = conn.prepareStatement("drop table if exists test_llt")
        var rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test_llt(data bigint NOT NULL, datanull varchar(20))")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        // 第一行：setNull 显式 NULL 参数
        prepareStatement = conn.prepareStatement("insert into test_llt values(?,?)")
        prepareStatement.set<Int64>(0, 42)
        prepareStatement.setNull(1)
        rowCount = prepareStatement.update()
        @Assert(1, rowCount.rowCount)
        // 第二行：字符串参数
        prepareStatement.set<Int64>(0, 43)
        prepareStatement.set<String>(1, "abc")
        rowCount = prepareStatement.update()
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test_llt order by data")
        var queryResult = prepareStatement.query()
        // 第一行
        @Assert(true, queryResult.next())
        @Assert(42, queryResult.get<Int64>(0))
        @Assert(None, queryResult.getOrNull<String>(1))
        // 第二行
        @Assert(true, queryResult.next())
        @Assert(43, queryResult.get<Int64>(0))
        @Assert("abc", queryResult.get<String>(1))
        // 行尾
        @Assert(false, queryResult.next())
        queryResult.close()
        conn.close()
    }
}
