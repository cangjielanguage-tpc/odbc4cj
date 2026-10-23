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
    // 回归覆盖：set<T> 对不支持类型（Float16/Rune）设置时立即拒绝；
    // getMetaData 元数据键；close 后 isClosed 状态正确
    @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var prepareStatement = conn.prepareStatement("drop table if exists test_llt")
        var rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test_llt(data varchar(20) NOT NULL)")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test_llt values(?)")
        // Float16/Rune 不支持隐式转换，必须在 set 阶段立即抛出，而不是延迟到执行阶段
        var f16Threw = false
        try {
            var f: Float16 = 1.0
            prepareStatement.set<Float16>(0, f)
        } catch (e: SqlException) {
            f16Threw = true
        }
        @Assert(true, f16Threw)
        var runeThrew = false
        try {
            prepareStatement.set<Rune>(0, r'a')
        } catch (e: SqlException) {
            runeThrew = true
        }
        @Assert(true, runeThrew)

        // getMetaData 返回连接元数据，键包括 dbms.name 等
        var meta = conn.getMetaData()
        @Assert(true, meta.contains("dbms.name"))
        @Assert(true, meta.get("dbms.name").isSome())
        @Assert(true, meta.contains("driver.name"))
        conn.close()
        @Assert(true, conn.isClosed())
    }
}
