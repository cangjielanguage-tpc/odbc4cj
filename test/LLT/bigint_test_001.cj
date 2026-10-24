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
    @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var prepareStatement = conn.prepareStatement("drop table if exists test_llt")
        var rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test_llt(data bigint NOT NULL, datanull bigint)")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test_llt values(?,?)")
        prepareStatement.set<Int64>(0, Int64.Max)
        prepareStatement.set<Option<Int64>>(1, Option<Int64>.None)
        // prepareStatement.setNull(1)
        rowCount = prepareStatement.update()
        @Assert(1, rowCount.rowCount)
        // 合法的 UInt64（未超过有符号 BIGINT 上限）必须无损绑定入库
        prepareStatement.set<UInt64>(0, UInt64(Int64.Max))
        prepareStatement.set<Option<UInt64>>(1, Option<UInt64>.None)
        rowCount = prepareStatement.update()
        @Assert(1, rowCount.rowCount)
        // 越界的 UInt64（超过有符号 BIGINT 上限）必须被数据库拒绝并抛出异常，而不是静默回绕写入错误数据
        var threwExpectedException = false
        try {
            prepareStatement.set<UInt64>(0, UInt64.Max)
            prepareStatement.set<Option<UInt64>>(1, Option<UInt64>.None)
            prepareStatement.update()
        } catch (e: OdbcSqlException) {
            threwExpectedException = true
            // MySQL 服务器越界错误码
            @Assert(1264, e.odbcNativeCode)
        }
        @Assert(true, threwExpectedException)
        prepareStatement = conn.prepareStatement("select * from test_llt")
        var queryResult = prepareStatement.query()
        let a = queryResult.next()
        @Assert(true, a)
        @Assert("SqlInt64", queryResult.columnInfos[0].typeName)
        @Assert("SqlInt64", queryResult.columnInfos[1].typeName)
        @Assert(Int64.Max, queryResult.get<Int64>(0))
        @Assert(None, queryResult.getOrNull<Int64>(1))
        queryResult.close()
    }
}
