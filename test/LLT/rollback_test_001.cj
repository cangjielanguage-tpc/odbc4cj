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
        var tran = conn.createTransaction()
        tran.begin()
        var prepareStatement = conn.prepareStatement("drop table if exists test_llt")
        var rowCount = prepareStatement.update()
        tran.commit()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test_llt(data int NOT NULL, datanull int)")
        rowCount = prepareStatement.update()
        tran.commit()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test_llt values(123,123)")
        tran.rollback()
        prepareStatement = conn.prepareStatement("insert into test_llt values(?,?)")
        prepareStatement.set<Int32>(0, 456)
        prepareStatement.set<Option<Int32>>(1, Option<Int32>.None)
        // prepareStatement.setNull(1)
        rowCount = prepareStatement.update()
        prepareStatement = conn.prepareStatement("select * from test_llt")
        var queryResult = prepareStatement.query()
        queryResult.next()
        tran.commit()
        @Assert("SqlInt32", queryResult.columnInfos[0].typeName)
        @Assert("SqlInt32", queryResult.columnInfos[1].typeName)
        @Assert(456, queryResult.get<Int32>(0))
        @Assert(None, queryResult.getOrNull<Int32>(1))
        queryResult.close()
    }
}
