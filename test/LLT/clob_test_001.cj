// EXEC: cjc %import-path %L %l %f
// EXEC: ./main

import std.database.sql.*
import std.io.*
import std.time.*
import std.regex.*
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
        prepareStatement = conn.prepareStatement("create table test_llt(data text(20) NOT NULL, datanull text(20))")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test_llt values(?,?)")
        var str = ByteBuffer(20)
        let arr1 = "上了飞机".toArray()
        str.write(arr1)
        prepareStatement.set<ByteBuffer>(0, str)
        prepareStatement.set<Option<InputStream>>(1, Option<InputStream>.None)
        // prepareStatement.setNull(1)
        rowCount = prepareStatement.update()
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test_llt")
        var queryResult = prepareStatement.query()
        let a = queryResult.next()
        @Assert(true, a)
        @Assert("SqlClob", queryResult.columnInfos[0].typeName)
        @Assert("SqlClob", queryResult.columnInfos[1].typeName)
        let inputStream: InputStream = queryResult.get<InputStream>(0)
        var arr = Array<UInt8>(arr1.size, repeat: 0)
        inputStream.read(arr)
        @Assert(arr1, arr)
        let inputStream1: ?InputStream = queryResult.getOrNull<InputStream>(1)
        match (inputStream1) {
            case Some(v) => @Assert(0, 1)
            case None => @Assert(1, 1)
        }
        queryResult.close()
    }
}
