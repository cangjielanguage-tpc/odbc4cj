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
    // 回归覆盖：UInt16/UInt32 无符号 C 类型绑定（SQL_C_USHORT/ULONG）
    // 修复前使用有符号绑定，超有符号范围的值被静默回绕写库
    @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var prepareStatement = conn.prepareStatement("drop table if exists test_llt")
        var rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test_llt(data int unsigned NOT NULL, data2 smallint unsigned NOT NULL)")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test_llt values(?,?)")
        // UInt32.Max = 4294967295 超过 Int32.Max，修复前经有符号绑定回绕为 -1294967296
        prepareStatement.set<UInt32>(0, UInt32.Max)
        prepareStatement.set<UInt16>(1, UInt16.Max)
        rowCount = prepareStatement.update()
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test_llt")
        var queryResult = prepareStatement.query()
        @Assert(true, queryResult.next())
        // 无符号列（SQL_DESC_UNSIGNED）读取走 UInt 通道，无符号值无损读回
        @Assert(4294967295, queryResult.get<UInt32>(0))
        @Assert(65535, queryResult.get<UInt16>(1))
        queryResult.close()

        // 有符号 int 列写入 UInt32.Max 必须被数据库拒绝（严格模式 1264），不能静默回绕
        prepareStatement = conn.prepareStatement("drop table if exists test_llt2")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test_llt2(data int NOT NULL)")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test_llt2 values(?)")
        var threwExpectedException = false
        try {
            prepareStatement.set<UInt32>(0, UInt32.Max)
            prepareStatement.update()
        } catch (e: OdbcSqlException) {
            threwExpectedException = true
            // MySQL 服务器越界错误码
            @Assert(1264, e.odbcNativeCode)
        }
        @Assert(true, threwExpectedException)
        conn.close()
    }
}
