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
        prepareStatement = conn.prepareStatement("create table test_llt(data BINARY(20) NOT NULL, datanull BINARY(20))")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test_llt values(?,?)")
        let arr: Array<Byte> = [0, 22]
        prepareStatement.set<Array<Byte>>(0, arr)
        prepareStatement.set<Option<Array<Byte>>>(1, Option<Array<Byte>>.None)
        // prepareStatement.setNull(1)
        rowCount = prepareStatement.update()
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test_llt")
        var queryResult = prepareStatement.query()
        let a = queryResult.next()
        @Assert(true, a)
        @Assert("SqlArrayByte", queryResult.columnInfos[0].typeName)
        @Assert("SqlArrayByte", queryResult.columnInfos[1].typeName)
        @Assert(arr, queryResult.get<Array<Byte>>(0)[..2])
        @Assert(None, queryResult.getOrNull<Array<Byte>>(1))
        queryResult.close()
    }
}
